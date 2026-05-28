const express = require('express');
const path = require('path');

const app = express();
const PORT = process.env.PORT ?? 80;

// Servir archivos estáticos desde src/public/ en la ruta raíz /
app.use('/', express.static(path.join(__dirname, 'public')));

// GET /health — retorna el estado del servicio en formato JSON
// Este endpoint es el que el pipeline de CI valida para producir el Check_Verde en GitHub Actions
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'UP',
    charla: 'Despliegue 101 con JavaScript',
  });
});

// Solo iniciar el servidor cuando el módulo se ejecuta directamente (node src/server.js)
// Cuando Supertest importa este módulo en los tests, el servidor NO se inicia
if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`JS_App escuchando en el puerto ${PORT}`);
  });
}

module.exports = app;
