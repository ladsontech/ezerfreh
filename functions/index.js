const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const logger = require('firebase-functions/logger');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

const region = 'us-central1';
const adminRoles = ['admin', 'Admin', 'ADMIN'];
const riderRoles = ['rider', 'Rider', 'RIDER'];
const hostingUrl = 'https://ezerfresh-f87af.web.app';

exports.notifyAdminsOnUserSignup = onDocumentCreated(
  { document: 'users/{userId}', region },
  async (event) => {
    const user = event.data.data() || {};
    const name = text(user.name, 'New user');
    const email = text(user.email, '');
    const body = email ? `${name} signed up with ${email}.` : `${name} signed up.`;

    await sendToRoles(adminRoles, {
      notification: {
        title: 'New user signup',
        body,
      },
      data: {
        type: 'user_signup',
        userId: event.params.userId,
      },
    });
  },
);

exports.notifyStaffOnOrderCreated = onDocumentCreated(
  { document: 'orders/{orderId}', region },
  async (event) => {
    const order = event.data.data() || {};
    const orderId = event.params.orderId;
    const total = formatMoney(order.totalAmount);
    const status = text(order.status, 'Pending');
    const adminBody = `A new order has been placed${total ? ` for ${total}` : ''}.`;
    const riderBody = `A new order is in the queue and is ${status.toLowerCase()}.`;

    await Promise.all([
      sendToRoles(adminRoles, {
        notification: {
          title: 'New order placed',
          body: adminBody,
        },
        data: {
          type: 'order_created',
          orderId,
          status,
        },
      }),
      sendToRoles(riderRoles, {
        notification: {
          title: 'New order in queue',
          body: riderBody,
        },
        data: {
          type: 'order_created',
          orderId,
          status,
        },
      }),
    ]);
  },
);

exports.notifyOrderStatusChanged = onDocumentUpdated(
  { document: 'orders/{orderId}', region },
  async (event) => {
    const before = event.data.before.data() || {};
    const after = event.data.after.data() || {};
    const previousStatus = text(before.status, '');
    const status = text(after.status, '');

    if (!status || status === previousStatus) {
      return;
    }

    const orderId = event.params.orderId;
    
    // Friendly customer-facing status messages
    let customerBody = `Your order status has been updated to ${status}.`;
    const lowerStatus = status.toLowerCase();
    if (lowerStatus === 'processing') {
      customerBody = 'Your order is being processed successfully.';
    } else if (lowerStatus === 'ready for pickup') {
      customerBody = 'Your order is ready for pickup.';
    } else if (lowerStatus === 'assigned') {
      customerBody = 'A delivery rider has been assigned to your order.';
    } else if (lowerStatus === 'picked up' || lowerStatus === 'on the way') {
      customerBody = 'Your order is on the way!';
    } else if (lowerStatus === 'arrived') {
      customerBody = 'Your order has arrived!';
    } else if (lowerStatus === 'completed') {
      customerBody = 'Your order has been successfully delivered and completed.';
    } else if (lowerStatus === 'cancelled') {
      customerBody = 'Your order has been cancelled.';
    }

    const tasks = [
      sendToRoles(adminRoles, {
        notification: {
          title: 'Order status changed',
          body: `Order changed status from ${previousStatus || 'Pending'} to ${status}.`,
        },
        data: {
          type: 'order_status_changed',
          orderId,
          previousStatus,
          status,
        },
      }),
    ];

    if (after.userId) {
      tasks.push(
        sendToUser(after.userId, {
          notification: {
            title: 'Order status updated',
            body: customerBody,
          },
          data: {
            type: 'order_status_changed',
            orderId,
            previousStatus,
            status,
          },
        }),
      );
    }

    if (status === 'Ready for Pickup') {
      tasks.push(
        sendToRoles(riderRoles, {
          notification: {
            title: 'Order ready for pickup',
            body: `A new order is ready for pickup in the queue.`,
          },
          data: {
            type: 'order_ready_for_pickup',
            orderId,
            status,
          },
        }),
      );
    }

    if (after.riderId && after.riderId !== before.riderId) {
      tasks.push(
        sendToUser(after.riderId, {
          notification: {
            title: 'Order assigned to you',
            body: `A new order has been assigned to you and is ${status.toLowerCase()}.`,
          },
          data: {
            type: 'order_assigned',
            orderId,
            status,
          },
        }),
      );
    }

    await Promise.all(tasks);
  },
);

async function sendToRoles(roles, payload) {
  const users = await db.collection('users').where('role', 'in', roles).get();
  const userIds = users.docs.map((doc) => doc.id);
  return sendToUsers(userIds, payload);
}

async function sendToUser(userId, payload) {
  return sendToUsers([userId], payload);
}

async function sendToUsers(userIds, payload) {
  const records = await getTokenRecords(userIds);
  return sendToTokenRecords(records, payload);
}

async function getTokenRecords(userIds) {
  const uniqueUserIds = [...new Set(userIds.filter(Boolean))];
  const snapshots = await Promise.all(
    uniqueUserIds.map((userId) =>
      db.collection('users').doc(userId).collection('fcmTokens').get(),
    ),
  );

  const records = [];
  snapshots.forEach((snapshot) => {
    snapshot.docs.forEach((doc) => {
      const token = doc.get('token');
      if (typeof token === 'string' && token.trim()) {
        records.push({ token, ref: doc.ref });
      }
    });
  });

  const seen = new Set();
  return records.filter((record) => {
    if (seen.has(record.token)) return false;
    seen.add(record.token);
    return true;
  });
}

async function sendToTokenRecords(records, payload) {
  if (records.length === 0) {
    logger.info('No FCM tokens for notification', payload.data || {});
    return;
  }

  const chunks = chunk(records, 500);
  for (const recordsChunk of chunks) {
    const message = {
      tokens: recordsChunk.map((record) => record.token),
      notification: payload.notification,
      data: stringifyData({
        title: payload.notification?.title,
        body: payload.notification?.body,
        ...(payload.data || {}),
      }),
      android: {
        priority: 'high',
        notification: {
          channelId: 'default',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
          },
        },
      },
      webpush: {
        fcmOptions: {
          link: hostingUrl,
        },
        notification: {
          icon: '/icons/Icon-192.png',
          badge: '/icons/Icon-192.png',
        },
      },
    };

    const response = await messaging.sendEachForMulticast(message);
    await deleteInvalidTokens(recordsChunk, response.responses);
    logger.info('FCM notification sent', {
      successCount: response.successCount,
      failureCount: response.failureCount,
      type: payload.data?.type,
    });
  }
}

async function deleteInvalidTokens(records, responses) {
  const invalidCodes = new Set([
    'messaging/invalid-registration-token',
    'messaging/registration-token-not-registered',
  ]);

  const deletes = [];
  responses.forEach((response, index) => {
    const code = response.error?.code;
    if (code && invalidCodes.has(code)) {
      deletes.push(records[index].ref.delete());
    }
  });

  await Promise.all(deletes);
}

function stringifyData(data) {
  return Object.fromEntries(
    Object.entries(data)
      .filter(([, value]) => value !== undefined && value !== null)
      .map(([key, value]) => [key, String(value)]),
  );
}

function chunk(items, size) {
  const chunks = [];
  for (let index = 0; index < items.length; index += size) {
    chunks.push(items.slice(index, index + size));
  }
  return chunks;
}

function text(value, fallback) {
  if (value === undefined || value === null) return fallback;
  const stringValue = String(value).trim();
  return stringValue || fallback;
}

function shortOrderId(orderId) {
  if (!orderId) return 'Order';
  return `#${orderId.slice(0, 8).toUpperCase()}`;
}

function formatMoney(value) {
  const amount = Number(value);
  if (!Number.isFinite(amount) || amount <= 0) return '';
  return `UGX ${Math.round(amount).toLocaleString('en-US')}`;
}
