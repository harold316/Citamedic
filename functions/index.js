const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { getStorage } = require('firebase-admin/storage');
const { HttpsError, onCall } = require('firebase-functions/v2/https');
const {
  onDocumentCreated,
  onDocumentUpdated,
} = require('firebase-functions/v2/firestore');

initializeApp();

const adminEmail = 'haroldisita666@gmail.com';
const channelId = 'citamedic_alerts';

exports.deleteDoctorAccount = onCall({ invoker: 'public' }, async (request) => {
  const caller = String(request.auth?.token?.email || '').toLowerCase();
  if (!request.auth || caller !== adminEmail) {
    throw new HttpsError(
      'permission-denied',
      'Solo un administrador puede eliminar cuentas.',
    );
  }
  const uid = typeof request.data?.uid === 'string' ? request.data.uid.trim() : '';
  if (!uid) {
    throw new HttpsError('invalid-argument', 'Falta el médico.');
  }
  if (uid === request.auth.uid) {
    throw new HttpsError(
      'failed-precondition',
      'No puedes eliminar tu propia cuenta.',
    );
  }

  await deleteAccountData(uid);
  await deleteAuthUser(uid, 'No se pudo borrar la cuenta de acceso del médico.');
  return { ok: true };
});

exports.deleteOwnAccount = onCall({ invoker: 'public' }, async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Debes iniciar sesión.');
  }
  const caller = String(request.auth.token?.email || '').toLowerCase();
  if (caller === adminEmail) {
    throw new HttpsError(
      'failed-precondition',
      'La cuenta de administrador no se puede eliminar aquí.',
    );
  }
  const uid = request.auth.uid;
  await deleteAccountData(uid);
  await deleteAuthUser(uid, 'No se pudo borrar tu cuenta de acceso.');
  return { ok: true };
});

async function deleteAccountData(uid) {
  const db = getFirestore();
  await Promise.all([
    db.collection('doctors').doc(uid).delete().catch(() => {}),
    db.collection('clinics').doc(uid).delete().catch(() => {}),
    db.collection('users').doc(uid).delete().catch(() => {}),
  ]);

  try {
    const [asPatient, asDoctor] = await Promise.all([
      db.collection('appointments').where('patientId', '==', uid).get(),
      db.collection('appointments').where('doctorId', '==', uid).get(),
    ]);
    const deletes = [...asPatient.docs, ...asDoctor.docs].map((doc) =>
      doc.ref.delete().catch(() => {}),
    );
    await Promise.all(deletes);
  } catch (error) {
    console.error('No se pudieron borrar citas de', uid, error);
  }

  try {
    await getStorage().bucket().deleteFiles({ prefix: `doctors/${uid}/` });
  } catch (error) {
    console.error('No se pudieron borrar las fotos del médico', uid, error);
  }
  try {
    await getStorage().bucket().deleteFiles({ prefix: `clinics/${uid}/` });
  } catch (error) {
    console.error('No se pudieron borrar las fotos de la clínica', uid, error);
  }
}

async function deleteAuthUser(uid, message) {
  try {
    await getAuth().deleteUser(uid);
  } catch (error) {
    if (error.code !== 'auth/user-not-found') {
      console.error('No se pudo borrar Auth', uid, error);
      throw new HttpsError('internal', message);
    }
  }
}

async function notifyUser(uid, { title, body, type, id }) {
  if (!uid) {
    return;
  }
  const db = getFirestore();
  const messaging = getMessaging();
  const snap = await db.collection('users').doc(uid).get();
  const token = snap.get('fcmToken');
  const payload = {
    notification: { title, body },
    data: {
      title,
      body,
      type: type || '',
      id: id || '',
    },
    android: {
      priority: 'high',
      notification: { channelId },
    },
    apns: {
      payload: { aps: { sound: 'default' } },
    },
  };
  try {
    if (typeof token === 'string' && token.length > 20) {
      await messaging.send({ token, ...payload });
      return;
    }
    await messaging.send({ topic: `user_${uid}`, ...payload });
  } catch (error) {
    console.error('No se pudo enviar FCM', uid, error);
  }
}

async function notifyTopic(topic, { title, body, type, id }) {
  try {
    await getMessaging().send({
      topic,
      notification: { title, body },
      data: {
        title,
        body,
        type: type || '',
        id: id || '',
      },
      android: {
        priority: 'high',
        notification: { channelId },
      },
    });
  } catch (error) {
    console.error('No se pudo enviar FCM al topic', topic, error);
  }
}

exports.notifyOnAppointment = onDocumentCreated(
  'appointments/{appointmentId}',
  async (event) => {
    const data = event.data?.data();
    if (!data) {
      return;
    }
    const doctorId = data.doctorId;
    const patientName = data.patientName || 'Un paciente';
    const serviceName = data.serviceName || 'una consulta';
    const message = typeof data.patientMessage === 'string'
      ? data.patientMessage.trim()
      : '';
    const preview = message.length > 80 ? `${message.slice(0, 77)}...` : message;
    await notifyUser(doctorId, {
      title: 'Nueva cita en CitaMedic',
      body: preview
        ? `${patientName} agendó ${serviceName}. ${preview}`
        : `${patientName} agendó ${serviceName}.`,
      type: 'appointment',
      id: event.params.appointmentId,
    });
  },
);

exports.notifyOnDoctorReview = onDocumentUpdated(
  'doctors/{doctorId}',
  async (event) => {
    const before = event.data?.before.data() || {};
    const after = event.data?.after.data() || {};
    if (
      before.published === after.published &&
      (before.reviewStatus || '') === (after.reviewStatus || '')
    ) {
      return;
    }
    const doctorId = event.params.doctorId;
    const name = after.name || 'Médico';
    const wasPublished = before.published === true;
    const isPublished = after.published === true;
    const beforeStatus = before.reviewStatus || '';
    const afterStatus = after.reviewStatus || '';

    if (!wasPublished && isPublished) {
      await notifyUser(doctorId, {
        title: 'Perfil publicado',
        body: 'Un administrador verificó tus datos. Ya eres visible para los pacientes.',
        type: 'review',
        id: doctorId,
      });
      return;
    }

    if (beforeStatus !== 'rejected' && afterStatus === 'rejected') {
      const reason = after.rejectionReason
        ? ` Motivo: ${after.rejectionReason}`
        : '';
      await notifyUser(doctorId, {
        title: 'Perfil rechazado',
        body: `Revisa tus datos y vuelve a enviarlos.${reason}`,
        type: 'review',
        id: doctorId,
      });
      return;
    }

    if (beforeStatus !== 'pending' && afterStatus === 'pending') {
      await notifyTopic('admins', {
        title: 'Perfil médico por revisar',
        body: `${name} envió sus datos para verificación.`,
        type: 'admin_review',
        id: doctorId,
      });
    }
  },
);
