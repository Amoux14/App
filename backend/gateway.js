import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

const gatewayPort = Number(process.env.GATEWAY_PORT || 4000);
const targetBaseUrl = process.env.BACKEND_URL || 'http://127.0.0.1:3000';

async function forwardRequest(req, res) {
  const url = new URL(req.originalUrl, targetBaseUrl).toString();
  const init = {
    method: req.method,
    headers: { ...req.headers },
    redirect: 'manual',
  };

  delete init.headers.host;

  if (req.method !== 'GET' && req.method !== 'HEAD') {
    init.body = JSON.stringify(req.body);
  }

  try {
    const backendResponse = await fetch(url, init);
    const responseText = await backendResponse.text();

    backendResponse.headers.forEach((value, name) => {
      const skip = [
        'transfer-encoding',
        'content-length',
        'connection',
        'keep-alive',
        'upgrade',
        'proxy-authenticate',
        'proxy-authorization',
        'te',
      ];
      if (!skip.includes(name.toLowerCase())) {
        res.setHeader(name, value);
      }
    });

    res.status(backendResponse.status).send(responseText);
  } catch (error) {
    console.error('Gateway proxy error:', error);
    res.status(502).json({ message: 'Gateway error contacting backend.' });
  }
}

app.all(['/health', '/api/*'], forwardRequest);

app.all('*', (_req, res) => {
  res.status(404).json({ message: 'Gateway route not found.' });
});

app.listen(gatewayPort, () => {
  console.log(`Gateway listening on http://127.0.0.1:${gatewayPort}`);
  console.log(`Forwarding requests to backend at ${targetBaseUrl}`);
});
