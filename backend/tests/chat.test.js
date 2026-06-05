// tests/chat.test.js
//
// Chat endpoints — group create, my-group lookup, send, history।  Group
// auto-naming uses the user's full name; sender info join verified।

const request = require('supertest');

const { buildApp, signToken, prismaMock } = require('./helpers/testApp');

let app;
beforeAll(() => {
  app = buildApp();
});

beforeEach(() => {
  prismaMock.reset();
});

// ─────────────────────────────────────────────────────────────────────
// POST /api/chat/create-group
// ─────────────────────────────────────────────────────────────────────
describe('POST /api/chat/create-group', () => {
  it('uses owner.fullName for auto group name', async () => {
    const token = signToken({ id: 'owner-1' });

    prismaMock.user.findUnique.mockResolvedValueOnce({
      id: 'owner-1',
      fullName: 'Karim Studio',
    });
    prismaMock.chatGroup.create.mockResolvedValueOnce({
      id: 'g-1',
      name: "Karim Studio's Team Chat",
      ownerId: 'owner-1',
    });

    const res = await request(app)
      .post('/api/chat/create-group')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.data.name).toBe("Karim Studio's Team Chat");

    expect(prismaMock.chatGroup.create).toHaveBeenCalledWith({
      data: { name: "Karim Studio's Team Chat", ownerId: 'owner-1' },
    });
  });

  it('Authorization missing → 401', async () => {
    const res = await request(app).post('/api/chat/create-group');
    expect(res.status).toBe(401);
  });
});

// ─────────────────────────────────────────────────────────────────────
// GET /api/chat/my-group
// ─────────────────────────────────────────────────────────────────────
describe('GET /api/chat/my-group', () => {
  it('returns the owner\'s group', async () => {
    const token = signToken({ id: 'owner-1' });
    prismaMock.chatGroup.findFirst.mockResolvedValueOnce({
      id: 'g-1',
      ownerId: 'owner-1',
    });

    const res = await request(app)
      .get('/api/chat/my-group')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(prismaMock.chatGroup.findFirst).toHaveBeenCalledWith({
      where: { ownerId: 'owner-1' },
    });
  });

  it('no group → 404', async () => {
    const token = signToken();
    prismaMock.chatGroup.findFirst.mockResolvedValueOnce(null);

    const res = await request(app)
      .get('/api/chat/my-group')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(404);
  });
});

// ─────────────────────────────────────────────────────────────────────
// POST /api/chat/send
// ─────────────────────────────────────────────────────────────────────
describe('POST /api/chat/send', () => {
  it('persists message with senderId from JWT', async () => {
    const token = signToken({ id: 'staff-1' });
    prismaMock.chatMessage.create.mockResolvedValueOnce({
      id: 'm-1',
      groupId: 'g-1',
      senderId: 'staff-1',
      text: 'Hello team',
    });

    const res = await request(app)
      .post('/api/chat/send')
      .set('Authorization', `Bearer ${token}`)
      .send({ groupId: 'g-1', text: 'Hello team' });

    expect(res.status).toBe(201);

    expect(prismaMock.chatMessage.create).toHaveBeenCalledWith({
      data: { groupId: 'g-1', senderId: 'staff-1', text: 'Hello team' },
    });
  });
});

// ─────────────────────────────────────────────────────────────────────
// GET /api/chat/messages/:groupId
// ─────────────────────────────────────────────────────────────────────
describe('GET /api/chat/messages/:groupId', () => {
  it('returns messages chronologically with sender info joined', async () => {
    const token = signToken();
    prismaMock.chatMessage.findMany.mockResolvedValueOnce([
      {
        id: 'm-1',
        text: 'Hi',
        sentAt: new Date('2025-01-01'),
        sender: { fullName: 'Karim', role: 'OWNER' },
      },
    ]);

    const res = await request(app)
      .get('/api/chat/messages/g-1')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.data[0].sender.fullName).toBe('Karim');

    expect(prismaMock.chatMessage.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { groupId: 'g-1' },
        include: {
          sender: { select: { fullName: true, role: true } },
        },
        orderBy: { sentAt: 'asc' },
      }),
    );
  });
});

// ─────────────────────────────────────────────────────────────────────
// Error paths
// ─────────────────────────────────────────────────────────────────────
describe('Chat — error paths', () => {
  it('createTeamGroup → 500 on Prisma error', async () => {
    const token = signToken();
    prismaMock.user.findUnique.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .post('/api/chat/create-group')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(500);
  });

  it('sendMessage → 500 on Prisma error', async () => {
    const token = signToken();
    prismaMock.chatMessage.create.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .post('/api/chat/send')
      .set('Authorization', `Bearer ${token}`)
      .send({ groupId: 'g1', text: 'hi' });

    expect(res.status).toBe(500);
  });

  it('getMessages → 500 on Prisma error', async () => {
    const token = signToken();
    prismaMock.chatMessage.findMany.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .get('/api/chat/messages/g1')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(500);
  });

  it('getMyTeamGroup → 500 on Prisma error', async () => {
    const token = signToken();
    prismaMock.chatGroup.findFirst.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .get('/api/chat/my-group')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(500);
  });
});
