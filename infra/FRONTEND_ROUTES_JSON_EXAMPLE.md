# Static Web Apps Routes Configuration

Azure Static Web Apps requires a `routes.json` file to handle Angular routing properly. Without this file, Angular routes (like `/whiteboard` or `/telehealth`) will return 404 errors.

## Solution: Create routes.json

Create a `routes.json` file in your Angular project's `public` folder (or `src/assets` folder).

### File Location

**Option 1**: `public/routes.json` (recommended)

**Option 2**: `src/assets/routes.json` (if you don't have a public folder)

### routes.json Content

```json
{
  "routes": [
    {
      "route": "/*",
      "serve": "/index.html",
      "statusCode": 200
    }
  ],
  "navigationFallback": {
    "rewrite": "/index.html",
    "exclude": ["/api/*", "*.{css,scss,js,png,gif,ico,jpg,svg,woff,woff2,ttf,eot}"]
  },
  "responseOverrides": {
    "404": {
      "rewrite": "/index.html",
      "statusCode": 200
    }
  }
}
```

### Explanation

- **`routes`**: Defines routing rules
  - `/*`: Matches all routes
  - `serve`: Serves `index.html` for all routes (Angular handles routing client-side)
  - `statusCode`: Returns 200 (not 404)

- **`navigationFallback`**: Fallback for navigation
  - `rewrite`: Rewrites all routes to `index.html`
  - `exclude`: Excludes API routes and static assets from rewriting

- **`responseOverrides`**: Override 404 responses
  - `404`: Rewrites 404 errors to `index.html` with 200 status

## Add to Angular.json

To ensure `routes.json` is copied to the build output, add it to `angular.json`:

```json
{
  "projects": {
    "your-app-name": {
      "architect": {
        "build": {
          "options": {
            "assets": [
              "src/favicon.ico",
              "src/assets",
              {
                "glob": "routes.json",
                "input": "public",
                "output": "/"
              }
            ]
          }
        }
      }
    }
  }
}
```

**Note**: Replace `your-app-name` with your actual Angular app name.

## Verify

After building your Angular app, verify `routes.json` is in the `dist/` folder:

```bash
# Build your app
ng build --configuration production

# Check if routes.json exists in dist folder
ls dist/<your-app-name>/routes.json
```

## Alternative: Minimal Configuration

If you only need basic routing, you can use this minimal configuration:

```json
{
  "routes": [
    {
      "route": "/*",
      "serve": "/index.html",
      "statusCode": 200
    }
  ]
}
```

## Testing

After deployment:

1. Navigate to `https://fd-agilis-dev.azurefd.net` → Should load main app
2. Navigate to `https://fd-agilis-dev.azurefd.net/whiteboard` → Should load whiteboard (not 404)
3. Navigate to `https://fd-agilis-dev.azurefd.net/telehealth` → Should load telehealth (not 404)

If you get 404 errors, verify:
- `routes.json` exists in your `dist/` folder
- `routes.json` is correctly formatted (valid JSON)
- Routes are deployed to Static Web App

