const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const {
  onDocumentCreated,
  onDocumentUpdated,
} = require('firebase-functions/v2/firestore');

initializeApp();

const channelId = 'citamedic_alerts';

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
    await notifyUser(doctorId, {
      title: 'Nueva cita en CitaMedic',
      body: `${patientName} agendó ${serviceName}.`,
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
