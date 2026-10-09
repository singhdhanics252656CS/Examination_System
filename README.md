ExamHub

An online exam system built with JSP and Tomcat. Teachers create exams, students take them, results show instantly.

Features

· Signup/login for students & teachers, login for admin
· Role-based dashboards
· Teachers create MCQ & long-answer exams
· Timed exams with auto-submit
· MCQs auto-marked, long answers graded by teachers
· Scores, top 10 leaderboard, study materials, feedback, profiles
· Admin manages users, exams, feedback

Roles

Students take exams and send feedback. Teachers create exams, mark their own, add materials. Admins delete any exam, read/delete feedback, and delete users.

Stack

JSP on Tomcat 10, Java 17, HTML/CSS, minimal JS, JSON with Gson, Docker.

Structure

All files in one flat folder. Db.java handles data, _top.jspf/_bot.jspf are shared partials, and each page (login.jsp, dashboard.jsp, exams.jsp, etc.) is a JSP. Dockerfile handles deployment.

How It Works

JSP pages run server-side, read/write via Db.java, and return HTML. Data lives in examhub.json in the temp folder. MCQs auto-mark; long answers wait for teachers. Unmarked exams keep students off the leaderboard.

Creating an Exam

One question per line:

```
mcq|Question|A|B|C|D|correct(1-4)|marks
long|Question|marks
```

Example:

```
mcq|What is 2+2?|3|4|5|6|2|2
long|Explain photosynthesis.|5
```

Bad lines are silently skipped.

Running Locally

```
docker build -t examhub .
docker run -p 8080:8080 examhub
```

Open http://localhost:8080

Deploying on Render

Push to GitHub, create a Web Service, set language to Docker, add PORT=8080, deploy.

Demo Accounts

· student@examhub.com / student123
· teacher@examhub.com / teacher123
· admin@examhub.com / admin123

Notes

Plain-text passwords (demo only). Data wipes on restart on free hosts. No anti-cheating.

Static Version

index.html is a single-file version using localStorage. Works on Netlify, but data is per-device.

Future

Hash passwords, real database, question banks, negative marking, PDF export.
