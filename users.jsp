<%@ include file="_top.jspf" %>
<%
if(!"admin".equals(role)){response.sendRedirect("dashboard.jsp");return;}
if("POST".equals(request.getMethod())){
 String uid=request.getParameter("id");
 Map<String,String> u=Db.find("users","id",uid);
 if(u!=null&&!uid.equals(me.get("id"))){
  Db.t("users").remove(u);
  Db.t("results").removeIf(r->uid.equals(r.get("stu")));
  Db.save();
 }
 response.sendRedirect("users.jsp");return;
}
%>
<h2>Users</h2><div class="card">
<% for(Map<String,String> u:Db.t("users")){%>
<div class="row"><span><%=Db.h(u.get("name"))%><br><span class="mut sm"><%=Db.h(u.get("email"))%>, <%=u.get("role")%></span></span>
<% if(!u.get("id").equals(me.get("id"))){%><form method="post"><input type="hidden" name="id" value="<%=u.get("id")%>"><button class="d">Delete</button></form><%}%></div>
<% } %></div>
<%@ include file="_bot.jspf" %>
