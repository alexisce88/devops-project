const request = require('supertest');

// Mock pg Pool before requiring the app
jest.mock('pg', () => {
  const mPool = {
    query: jest.fn(),
  };
  return { Pool: jest.fn(() => mPool) };
});

const { Pool } = require('pg');
const mockPool = new Pool();

let app, server;

beforeAll(() => {
  // Default mock: DB init succeeds
  mockPool.query.mockResolvedValue({ rows: [], rowCount: 1 });
  ({ app, server } = require('../src/index'));
});

afterAll((done) => {
  server.close(done);
});

afterEach(() => {
  jest.clearAllMocks();
});

describe('GET /health', () => {
  it('should return 200 with status ok', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('ok');
  });
});

describe('GET /status', () => {
  it('should return 200 when DB is connected', async () => {
    mockPool.query.mockResolvedValueOnce({ rows: [{ '?column?': 1 }] });
    const res = await request(app).get('/status');
    expect(res.statusCode).toBe(200);
    expect(res.body.db).toBe('connected');
  });

  it('should return 503 when DB is unavailable', async () => {
    mockPool.query.mockRejectedValueOnce(new Error('Connection refused'));
    const res = await request(app).get('/status');
    expect(res.statusCode).toBe(503);
    expect(res.body.db).toBe('disconnected');
  });
});

describe('GET /items', () => {
  it('should return list of items', async () => {
    const mockItems = [
      { id: 1, name: 'Item Alpha', created_at: new Date().toISOString() },
      { id: 2, name: 'Item Beta', created_at: new Date().toISOString() },
    ];
    mockPool.query.mockResolvedValueOnce({ rows: mockItems });
    const res = await request(app).get('/items');
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveLength(2);
    expect(res.body[0].name).toBe('Item Alpha');
  });

  it('should return 500 on DB error', async () => {
    mockPool.query.mockRejectedValueOnce(new Error('DB error'));
    const res = await request(app).get('/items');
    expect(res.statusCode).toBe(500);
  });
});

describe('POST /items', () => {
  it('should create a new item', async () => {
    const newItem = { id: 3, name: 'New Item', created_at: new Date().toISOString() };
    mockPool.query.mockResolvedValueOnce({ rows: [newItem] });
    const res = await request(app).post('/items').send({ name: 'New Item' });
    expect(res.statusCode).toBe(201);
    expect(res.body.name).toBe('New Item');
  });

  it('should return 400 if name is missing', async () => {
    const res = await request(app).post('/items').send({});
    expect(res.statusCode).toBe(400);
  });

  it('should return 400 if name is empty string', async () => {
    const res = await request(app).post('/items').send({ name: '  ' });
    expect(res.statusCode).toBe(400);
  });
});
