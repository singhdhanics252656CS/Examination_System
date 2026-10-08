<%@ page import="java.util.*,app.Db" contentType="text/html;charset=UTF-8" %>
<%
request.setCharacterEncoding("UTF-8");
String err=null;
if("POST".equals(request.getMethod())){
 String em=String.valueOf(request.getParameter("email")).trim().toLowerCase();
 String r=String.valueOf(request.getParameter("role"));
 String p=String.valueOf(request.getParameter("pass"));
 String n=String.valueOf(request.getParameter("name")).trim();
 if(!r.equals("student")&&!r.equals("teacher"))err="Choose student or teacher.";
 else if(n.isEmpty()||p.length()<6)err="Enter your name and a password of 6+ characters.";
 else if(Db.find("users","email",em)!=null)err="This email is already registered.";
 else{
  Map<String,String> u=Db.row("id",Db.id(),"role",r,"name",n,"email",em,"pass",p);
  Db.t("users").add(u);Db.save();
  session.setAttribute("uid",u.get("id"));response.sendRedirect("dashboard.jsp");return;
 }
}
%>
<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Sign up - ExamHub</title><link rel="stylesheet" href="style.css"></head>
<body><div class="box"><h1>Create account</h1>
<% if(err!=null){%><p class="err"><%=err%></p><%}%>
<form method="post"><input name="name" placeholder="Full name" required><input name="email" type="email" placeholder="Email" required><input name="pass" type="password" placeholder="Password (min 6 characters)" minlength="6" required>
<select name="role"><option value="student">Student</option><option value="teacher">Teacher</option></select>
<button>Create account</button></form>
<p>Already registered? <a href="login.jsp">Login</a></p></div></body></html>
