# BBMS — Running the Project Locally

Follow these steps to run the Blood Bank Management System (BBMS) on your local machine.

## Prerequisites

Make sure you have the following installed:

- [Node.js](https://nodejs.org/) and npm
- MySQL Server 8.0 or a compatible version
- MySQL Workbench (recommended for database management)

## 1. Open the Project Folder

Open Command Prompt (CMD) and navigate to the project directory:

```cmd
cd "C:\Users\<YOUR_USERNAME>\OneDrive\Desktop\DBMS\bbms-retake\bbms-github"
```

Replace the path with the location where you cloned or downloaded the repository.

## 2. Install Dependencies

Install the required Node.js packages:

```cmd
npm.cmd install
```

This installs the dependencies listed in `package.json`, including Express and the MySQL driver.

If PowerShell blocks `npm` because script execution is disabled, use `npm.cmd` or run the commands in Command Prompt.

## 3. Configure Environment Variables

Create a `.env` file in the project root directory, alongside `server.js` and `package.json`.

Add the following configuration:

```dotenv
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_mysql_password
DB_NAME=blood_bank_db
```

Replace `your_mysql_password` with your local MySQL password.

The server should load these variables using:

```javascript
require('dotenv').config();
```

The MySQL connection in `server.js` should use the environment variables:

```javascript
const pool = mysql.createPool({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME || 'blood_bank_db'
});
```

**Security:** Never commit `.env` or actual database passwords to GitHub. The repository's `.gitignore` should include `.env` and `node_modules/`.

## 4. Set Up the Database

1. Start the MySQL Server service.
2. Open MySQL Workbench and connect to your local MySQL instance.
3. Ensure that the `blood_bank_db` database exists and the required tables, triggers, and other database objects have been created.

If setting up the database for the first time, inspect `setup.js`, `package.json`, and the SQL files to follow the project's intended setup procedure.

Do not rerun database setup scripts on an existing database without checking whether they might modify or overwrite existing data.

## 5. Start the BBMS Server

In CMD, ensure that you are inside the project root directory and run:

```cmd
npm.cmd start
```

Alternatively, if necessary, run:

```cmd
node server.js
```

Keep the terminal open while using the website. The server must remain running.

## 6. Open the Website

Open your browser and navigate to:

**http://localhost:3000**

The application should now be accessible locally.

## 7. Troubleshooting

### `npm` is not recognized or PowerShell blocks `npm.ps1`

Use Command Prompt or run:

```cmd
npm.cmd install
npm.cmd start
```

### `Cannot find module 'express'`

Install the project dependencies from the project root:

```cmd
npm.cmd install
```

### `EADDRINUSE: address already in use :::3000`

Another process is already using port 3000, possibly an existing BBMS server.

Identify the process:

```cmd
netstat -ano | findstr :3000
```

Check the PID shown at the end of the `LISTENING` line:

```cmd
tasklist /FI "PID eq <PID>"
```

If the process is an old BBMS Node.js server, stop it using:

```cmd
taskkill /PID <PID> /F
```

Replace `<PID>` with the actual process ID. Do not terminate an unidentified process.

Then start BBMS again:

```cmd
npm.cmd start
```

### `Access denied for user 'root'@'localhost'`

Verify that:

- The MySQL username and password are correct.
- The `.env` file is in the project root.
- `dotenv` is installed and loaded before the database connection is created.
- The MySQL user has the necessary permissions.

### Staff dropdown is empty or an API request fails

1. Open the browser's Developer Tools using `F12`.
2. Go to the **Network** tab and refresh the page.
3. Inspect the relevant `/api/public` request and its response.
4. Check the terminal running `server.js` for backend or database errors.

### `.env` reports zero loaded variables

Check that `.env` exists in the same folder as `server.js`, contains the expected variable names, and is saved as `.env` rather than `.env.txt`.

## Important Notes

- `localhost` is accessible only from your own machine.
- MySQL Server must be running for database-backed features to work.
- Keep the terminal open while the application is running.
- This guide covers local development. Deployment requires a separately accessible database and appropriate production environment variables.
- Before deploying, ensure that database credentials are stored in the hosting provider's environment settings rather than hardcoded in source code.
