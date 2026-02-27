require('dotenv').config();
const http = require('http');
const { Server } = require('socket.io');
const app = require('./src/app');
const connectDB = require('./src/config/db');

const PORT = process.env.PORT || 5000;

const server = http.createServer(app);

// Socket.io for live metric streaming to debug panel
const io = new Server(server, {
    cors: { origin: "*" }
});

io.on('connection', (socket) => {
    console.log(`🟢 CHARMER client connected: ${socket.id}`);

    // Join a session room for metric updates
    socket.on('join_session', (sessionId) => {
        socket.join(sessionId);
        console.log(`Client joined session: ${sessionId}`);
    });

    // Stream pipeline metrics to debug panel
    socket.on('pipeline_update', (data) => {
        socket.to(data.sessionId).emit('metrics_update', {
            stage: data.stage,
            latency_ms: data.latency_ms,
            info_density: data.info_density,
            phonetic_accuracy: data.phonetic_accuracy,
            timestamp: new Date()
        });
    });

    socket.on('disconnect', () => {
        console.log(`🔴 Client disconnected: ${socket.id}`);
    });
});

// Make io accessible to routes
app.set('io', io);

connectDB().then(() => {
    server.listen(PORT, () => {
        console.log(`🚀 CHARMER API & Live Metrics running on port ${PORT}`);
    });
});