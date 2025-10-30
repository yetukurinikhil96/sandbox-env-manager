# Sandbox Environment Portal

A modern web portal for managing Azure sandbox environments.

## Features

- ? View all sandbox environments in a clean table
- ? Real-time status updates (Running, Starting, Stopped)
- ? Create new environments with custom configuration
- ? View detailed environment information
- ? Delete environments with confirmation
- ? Auto-refresh every 30 seconds
- ? Responsive Bootstrap design
- ? No server-side framework required

## Quick Start

### 1. Start the API

```bash
cd ../api
npm install
npm start
```

The API will run on `http://localhost:3000`

### 2. Open the Portal

Simply open `index.html` in your browser:

```bash
# Open directly
open index.html  # macOS
start index.html # Windows
xdg-open index.html # Linux

# Or serve with a simple HTTP server
python -m http.server 8080
# Then visit: http://localhost:8080
```

## API Integration

The portal connects to the REST API at `http://localhost:3000/api`:

### Endpoints Used:

- `GET /api/envs` - List all environments (loads table)
- `GET /api/envs/:name` - Get environment details (view details modal)
- `POST /api/envs` - Create new environment (create button)
- `DELETE /api/envs/:name` - Delete environment (delete button)

### API Configuration

Edit `js/site.js` to change the API URL:

```javascript
const API_BASE_URL = 'http://localhost:3000/api';
```

## Features

### Environment Table

Displays all environments with:
- Name
- Status (with color-coded badges)
- Resource Group
- AKS Cluster
- Region
- Creation date
- Action buttons (View Details, Delete)

### Create Environment

Click "Create Environment" to:
1. Enter environment name (e.g., `env-nikhil-01`)
2. Select Azure region
3. Choose node count
4. Click Create

**Note**: Environment creation takes 5-10 minutes for the AKS cluster.

### Empty State

When no environments exist, shows a friendly message:
> "No sandbox environments created"

### Auto-Refresh

The portal automatically refreshes the environment list every 30 seconds to show updated statuses.

## File Structure

```
portal/
??? index.html          # Main portal page
??? js/
?   ??? site.js        # JavaScript for API integration
??? css/
?   ??? site.css       # Custom styles
??? README.md          # This file
```

## Customization

### Change Styling

Edit `css/site.css` to customize colors, fonts, and layout.

### Modify API URL

If your API runs on a different port, update `js/site.js`:

```javascript
const API_BASE_URL = 'http://localhost:5000/api';  // Change port
```

### Add Features

The portal uses vanilla JavaScript with Bootstrap 5. You can easily add:
- Filters and search
- Sorting
- Pagination
- Export to CSV
- More environment details

## Browser Compatibility

Tested and working on:
- ? Chrome/Edge (latest)
- ? Firefox (latest)
- ? Safari (latest)

## Troubleshooting

### Portal shows "Failed to load environments"

1. Check if API is running: `http://localhost:3000/api/health`
2. Check browser console (F12) for errors
3. Verify CORS is enabled in API (it should be by default)

### Create button doesn't work

1. Ensure API is running on port 3000
2. Check browser console for errors
3. Verify the API endpoint returns success

### Environment status shows "Unknown"

This is normal if:
- Azure CLI is not authenticated
- Resource group doesn't exist yet
- API cannot query Azure

## Production Deployment

### Option 1: Static Hosting

Deploy to:
- Azure Static Web Apps
- GitHub Pages
- Netlify
- Vercel

### Option 2: With API

Deploy together:
- Azure Container Apps (API + Static files)
- Azure App Service
- Docker container with both API and portal

### CORS Configuration

For production, update API CORS settings in `api/.env`:

```env
CORS_ORIGINS=https://your-portal-domain.com
```

## Security

For production use:

1. ? Add authentication (Azure AD, OAuth)
2. ? Use HTTPS only
3. ? Implement rate limiting
4. ? Add input validation
5. ? Use environment variables for API URL

## License

Same as main project

## Support

See main project README for support information.
