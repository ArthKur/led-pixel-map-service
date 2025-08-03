# LED Pixel Map Cloud Service

A Python Flask service for generating large LED pixel maps in the cloud, removing browser Canvas API limitations.

## Features

- ✅ **Unlimited Image Sizes**: No browser Canvas API 32K×32K limits
- ✅ **Actual LED Panel Pixels**: Uses real LED product specifications (200×200px for Absen, etc.)
- ✅ **Fast Cloud Generation**: Optimized Python PIL rendering
- ✅ **CORS Enabled**: Works with Flutter web apps
- ✅ **Memory Efficient**: Handles 100M+ pixel images
- ✅ **Free Hosting**: Runs on Render.com free tier

## API Endpoints

### `GET /`
Health check endpoint
```json
{
  "status": "healthy",
  "service": "LED Pixel Map Cloud Renderer",
  "version": "1.0.0"
}
```

### `POST /generate-pixel-map`
Generates pixel map based on LED panel configuration

**Request Body:**
```json
{
  "surface": {
    "panelsWidth": 200,
    "fullPanelsHeight": 10,
    "halfPanelsHeight": 0,
    "panelPixelWidth": 200,
    "panelPixelHeight": 200,
    "ledName": "Absen PL2.5 Lite"
  },
  "config": {
    "surfaceIndex": 0,
    "showGrid": true,
    "showPanelNumbers": true
  }
}
```

**Response:**
```json
{
  "success": true,
  "image_base64": "iVBORw0KGgoAAAANSUhEUgAA...",
  "dimensions": {
    "width": 40000,
    "height": 2000,
    "panels_width": 200,
    "panels_height": 10
  },
  "file_size_mb": 45.2,
  "led_info": {
    "name": "Absen PL2.5 Lite",
    "panel_pixels": "200×200"
  }
}
```

## Deployment Steps

### 1. Create Render.com Account
- Go to [render.com](https://render.com)
- Sign up with GitHub account

### 2. Create New Web Service
- Click "New +" → "Web Service"
- Connect GitHub repository
- Select this folder: `cloud_pixel_service`

### 3. Configure Service
- **Name**: `led-pixel-map-service`
- **Environment**: `Python 3`
- **Build Command**: `pip install -r requirements.txt`
- **Start Command**: `gunicorn app:app`
- **Plan**: `Free`

### 4. Deploy
- Click "Create Web Service"
- Wait for deployment (2-3 minutes)
- Get service URL: `https://led-pixel-map-service.onrender.com`

## Local Testing

```bash
cd cloud_pixel_service
pip install -r requirements.txt
python app.py
```

Test endpoint:
```bash
curl http://localhost:5000/
```

## Integration with Flutter

The Flutter app will call this service instead of using browser Canvas API for large images.

Service URL will be: `https://your-service-name.onrender.com`
