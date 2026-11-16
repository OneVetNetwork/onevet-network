# OneVet Network

CS 370 Software Engineering Project

OneVet is a web application designed to help veterans find organizations and programs that offer assistance.

## Technologies

- React + Vite (Frontend)
- Python + FastAPI (Backend)
- Supabase PostgreSQL (Database)

## Current Progress

We have implemented an early prototype that allows users to:

- Browse veteran service organizations.
- Search and filter programs.
- View organization information and available services.
- Access links to official program websites.

The veteran profile and needs assessment features are still under development.

## Running the Project

### Backend

From the main project folder:

```powershell
py -m venv backend\.venv
.\backend\.venv\Scripts\python.exe -m pip install -r backend\requirements.txt
Copy-Item backend\.env.example backend\.env
```

Add the Supabase URL and publishable key to `backend/.env`.

Then start the server:

```powershell
.\backend\.venv\Scripts\python.exe -m uvicorn main:app --app-dir backend --reload
```

### Frontend

Open another terminal:

```powershell
cd frontend
npm.cmd install
Copy-Item .env.example .env
npm.cmd run dev
```

Open http://localhost:5173 in your browser.

## Database

We are using Supabase to store organization and program information.

The initial sample data can be added using `supabase/seed.sql` in the Supabase SQL Editor.

## Future Development

- Veteran profiles
- Needs assessment form
- Personalized program recommendations
- More organizations and programs

## Team

CS 370 - Team 11

Anthony Brunelle, Stan Stojanovich, Thiago Silva, Tristan Fababier