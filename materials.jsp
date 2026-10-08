<%@ include file="_top.jspf" %>
<%
if("POST".equals(request.getMethod())&&"teacher".equals(role)){
 if("del".equals(request.getParameter("act"))){
  Map<String,String> x=Db.find("materials","id",request.getParameter("id"));
  if(x!=null&&me.get("id").equals(x.get("by"))){Db.t("materials").remove(x);Db.save();}
 }else{
  String l=request.getParameter("link").trim();
  if(l.isEmpty()||l.matches("(?i)https?://.+")){
   Db.t("materials").add(Db.row("id",Db.id(),"title",request.getParameter("title").trim(),"subject",request.getParameter("subject").trim(),"desc",request.getParameter("desc").trim(),"link",l,"by",me.get("id")));
   Db.save();
  }
 }
 response.sendRedirect("materials.jsp");return;
}
%>
<h2>Exam material</h2>
<% if("teacher".equals(role)){%>
<form class="card" method="post"><h3>Add material</h3><input name="title" placeholder="Title" required><input name="subject" placeholder="Subject" required><textarea name="desc" rows="3" placeholder="Notes"></textarea><input name="link" type="url" placeholder="Link (optional, https://...)"><button>Add material</button></form>
<% }
for(Map<String,String> x:Db.t("materials")){%>
<div class="card"><b><%=Db.h(x.get("title"))%></b> <span class="tag"><%=Db.h(x.get("subject"))%></span><p><%=Db.h(x.get("desc"))%></p>
<% if(!x.get("link").isEmpty()){%><a href="<%=Db.h(x.get("link"))%>" target="_blank" rel="noopener">Open link</a><%}
if("teacher".equals(role)&&me.get("id").equals(x.get("by"))){%><form method="post"><input type="hidden" name="act" value="del"><input type="hidden" name="id" value="<%=x.get("id")%>"><button class="d">Delete</button></form><%}%>
</div>
<% } %>
<%@ include file="_bot.jspf" %>
