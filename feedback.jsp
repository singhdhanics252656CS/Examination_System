<%@ include file="_top.jspf" %>
<%
boolean adm="admin".equals(role);
if("POST".equals(request.getMethod())){
 if(adm){
  Map<String,String> f=Db.find("feedback","id",request.getParameter("id"));
  if(f!=null){Db.t("feedback").remove(f);Db.save();}
  response.sendRedirect("feedback.jsp");return;
 }
 String msg=request.getParameter("msg").trim();
 if(!msg.isEmpty()){
  Db.t("feedback").add(Db.row("id",Db.id(),"by",me.get("id"),"rate",""+Db.num(request.getParameter("rate"),5),"msg",msg,"at",new Date().toString()));
  Db.save();
 }
 response.sendRedirect("dashboard.jsp");return;
}
%>
<h2>Feedback</h2>
<% if(adm){
 for(Map<String,String> f:Db.t("feedback")){%>
<div class="card"><b><%=Db.h(Db.name(f.get("by")))%></b> rated <%=Db.h(f.get("rate"))%>/5<p><%=Db.h(f.get("msg"))%></p><p class="mut sm"><%=Db.h(f.get("at"))%></p>
<form method="post"><input type="hidden" name="id" value="<%=f.get("id")%>"><button class="d">Delete</button></form></div>
<% }
 if(Db.t("feedback").isEmpty()){%><p class="mut">No feedback yet.</p><%}
}else{%>
<form class="card" method="post"><select name="rate"><option value="5">5 - Excellent</option><option value="4">4 - Good</option><option value="3">3 - Okay</option><option value="2">2 - Poor</option><option value="1">1 - Bad</option></select>
<textarea name="msg" rows="4" placeholder="Tell us what to improve" required></textarea><button>Send feedback</button></form>
<% } %>
<%@ include file="_bot.jspf" %>
