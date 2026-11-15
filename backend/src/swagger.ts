export const swaggerDocument = {
  openapi: '3.0.0',
  info: {
    title: 'EldenCare REST API',
    version: '1.0.0',
    description: 'Cloud Synchronization, Role-Based Access Control and Healthcare Services for EldenCare.',
  },
  servers: [
    {
      url: 'http://localhost:3000/api/v1',
      description: 'Local Development Server',
    },
  ],
  components: {
    securitySchemes: {
      BearerAuth: {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
        description: 'Provide your verified Supabase user JWT.',
      },
    },
  },
  security: [{ BearerAuth: [] }],
  paths: {
    '/me': {
      get: {
        summary: 'Get Authenticated User Details',
        responses: { 200: { description: 'Success' }, 401: { description: 'Unauthorized' } },
      },
    },
    '/patients': {
      get: {
        summary: 'List Assigned Patients',
        responses: { 200: { description: 'Success' } },
      },
    },
    '/patients/{patientId}/overview': {
      get: {
        summary: 'Get Consolidated Patient Health Overview',
        parameters: [{ name: 'patientId', in: 'path', required: true, schema: { type: 'string' } }],
        responses: { 200: { description: 'Success' }, 403: { description: 'Forbidden' } },
      },
    },
    '/patients/{patientId}/medications': {
      get: {
        summary: 'List Patient Medications',
        parameters: [{ name: 'patientId', in: 'path', required: true, schema: { type: 'string' } }],
        responses: { 200: { description: 'Success' } },
      },
      post: {
        summary: 'Prescribe / Add Medication (Includes Duplicate Warning)',
        parameters: [{ name: 'patientId', in: 'path', required: true, schema: { type: 'string' } }],
        responses: { 201: { description: 'Created' }, 400: { description: 'Validation Error' } },
      },
    },
    '/task-instances/{instanceId}/confirmations': {
      post: {
        summary: 'Submit Independent Dual Task Confirmation',
        parameters: [{ name: 'instanceId', in: 'path', required: true, schema: { type: 'string' } }],
        responses: { 200: { description: 'Status calculated (verified or discrepancy)' } },
      },
    },
    '/patients/{patientId}/blood-pressure': {
      post: {
        summary: 'Log Blood Pressure Reading',
        parameters: [{ name: 'patientId', in: 'path', required: true, schema: { type: 'string' } }],
        responses: { 201: { description: 'Recorded' } },
      },
    },
    '/patients/{patientId}/glucose': {
      post: {
        summary: 'Log Blood Glucose Reading',
        parameters: [{ name: 'patientId', in: 'path', required: true, schema: { type: 'string' } }],
        responses: { 201: { description: 'Recorded' } },
      },
    },
    '/patients/{patientId}/care-plans': {
      post: {
        summary: 'Create / Update Doctor-Approved Care Plan',
        parameters: [{ name: 'patientId', in: 'path', required: true, schema: { type: 'string' } }],
        responses: { 201: { description: 'Care plan created' }, 403: { description: 'Doctor role required' } },
      },
    },
    '/care-plans/{planId}/activate': {
      post: {
        summary: 'Atomically Activate Care Plan Version',
        parameters: [{ name: 'planId', in: 'path', required: true, schema: { type: 'string' } }],
        responses: { 200: { description: 'Plan activated & prior versions superseded' } },
      },
    },
    '/patients/{patientId}/consultations': {
      post: {
        summary: 'Add Clinical Consultation Note',
        parameters: [{ name: 'patientId', in: 'path', required: true, schema: { type: 'string' } }],
        responses: { 201: { description: 'Consultation note recorded' } },
      },
    },
  },
};
