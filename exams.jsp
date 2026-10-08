<%@ include file="_top.jspf" %>
<%
if("POST".equals(request.getMethod())){
 String act=request.getParameter("act");
 if("create".equals(act)&&"teacher".equals(role)){
  List<Map<String,String>> q=new ArrayList<>();
  for(String ln:request.getParameter("qs").split("\\r?\\n")){
   String[] p=ln.split("\\|");
   Map<String,String> m=new LinkedHashMap<>();
   if(p.length>=8&&p[0].trim().equals("mcq")){
    m.put("t","mcq");m.put("q",p[1].trim());
    for(int i=0;i<4;i++)m.put("o"+i,p[2+i].trim());
    m.put("a",""+(Math.max(1,Math.min(4,Db.num(p[6],1)))-1));
    m.put("m",""+Db.num(p[7],1));q.add(m);
   }else if(p.length>=3&&p[0].trim().equals("long")){
    m.put("t","long");m.put("q",p[1].trim());m.put("m",""+Db.num(p[2],1));q.add(m);
   }
  }
  String title=request.getParameter("title").trim();
  if(!q.isEmpty()&&!title.isEmpty()){
   Db.t("exams").add(Db.row("id",Db.id(),"title",title,"subject",request.getParameter("subject").trim(),"dur",""+Db.num(request.getParameter("dur"),15),"by",me.get("id"),"q",Db.G.toJson(q)));
   Db.save();
  }
 }else if("del".equals(act)){
  Map<String,String> e=Db.find("exams","id",request.getParameter("id"));
  if(e!=null&&("admin".equals(role)||me.get("id").equals(e.get("by")))){
   String eid=e.get("id");
   Db.t("exams").remove(e);
   Db.t("results").removeIf(r->eid.equals(r.get("exam")));
   Db.save();
  }
 }
 response.sendRedirect("exams.jsp");return;
}
%>
<h2>Exams</h2>
<% if("teacher".equals(role)){ %>
<form class="card" method="post"><h3>Create exam</h3><input type="hidden" name="act" value="create">
<input name="title" placeholder="Exam title" required><input name="subject" placeholder="Subject" required><input name="dur" type="number" min="1" value="15" placeholder="Minutes">
<textarea name="qs" rows="7" required placeholder="One question per line:&#10;mcq|Question|A|B|C|D|correct option 1-4|marks&#10;long|Question|marks"></textarea>
<button>Publish exam</button></form>
<% }
for(Map<String,String> e:Db.t("exams")){
 if("teacher".equals(role)&&!me.get("id").equals(e.get("by")))continue;
 boolean done=false;
 for(Map<String,String> r:Db.t("results"))if(r.get("exam").equals(e.get("id"))&&r.get("stu").equals(me.get("id")))done=true;
%>
<div class="card"><b><%=Db.h(e.get("title"))%></b>
<p class="mut sm"><%=Db.h(e.get("subject"))%>, <%=Db.h(e.get("dur"))%> min, <%=Db.qs(e).size()%> questions. By <%=Db.h(Db.name(e.get("by")))%></p>
<% if("student".equals(role)){ if(done){ %><span class="tag">Completed</span><% }else{ %><a class="btn" href="take.jsp?id=<%=e.get("id")%>">Start exam</a><% } }else{ %>
<form method="post"><input type="hidden" name="act" value="del"><input type="hidden" name="id" value="<%=e.get("id")%>"><button class="d">Delete</button></form>
<% } %></div>
<% } %>
<%@ include file="_bot.jspf" %>
