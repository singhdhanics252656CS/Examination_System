<%@ page import="java.util.*,app.Db" contentType="text/html;charset=UTF-8" %>
<%
String err=null;
if("POST".equals(request.getMethod())){
 String em=String.valueOf(request.getParameter("email")).trim().toLowerCase();
 for(Map<String,String> u:Db.t("users"))
  if(u.get("email").equals(em)&&u.get("pass").equals(request.getParameter("pass"))&&u.get("role").equals(request.getParameter("role"))){
   session.setAttribute("uid",u.get("id"));response.sendRedirect("dashboard.jsp");return;}
 err="Wrong email, password or role.";
}
%>
<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Login - ExamHub</title><link rel="stylesheet" href="style.css"></head>
<body><div class="box"><h1>ExamHub</h1><p class="mut">Online examination system</p>
<% if(err!=null){%><p class="err"><%=err%></p><%}%>
<form method="post"><input name="email" type="email" placeholder="Email" required><input name="pass" type="password" placeholder="Password" required>
<select name="role"><option value="student">Student</option><option value="teacher">Teacher</option><option value="admin">Admin</option></select>
<button>Login</button></form>
<p>No account? <a href="signup.jsp">Sign up</a></p>
<p class="mut sm">Demo: student@examhub.com / student123, teacher@examhub.com / teacher123, admin@examhub.com / admin123</p></div></body></html>
