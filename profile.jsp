<%@ include file="_top.jspf" %>
<%
String note=null;
if("POST".equals(request.getMethod())){
 String n=request.getParameter("name").trim(),p=request.getParameter("pass");
 if(n.isEmpty()||(!p.isEmpty()&&p.length()<6))note="Name is required and the password needs 6+ characters.";
 else{me.put("name",n);if(!p.isEmpty())me.put("pass",p);Db.save();note="Profile updated.";}
}
%>
<h2>Profile</h2>
<form class="card" method="post"><p class="mut"><%=Db.h(me.get("email"))%>, <%=role%></p>
<% if(note!=null){%><p><%=note%></p><%}%>
<input name="name" value="<%=Db.h(me.get("name"))%>" required><input name="pass" type="password" placeholder="New password (leave blank to keep)"><button>Save changes</button></form>
<%@ include file="_bot.jspf" %>
