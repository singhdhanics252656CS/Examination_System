<%@ include file="_top.jspf" %>
<%
String err=null;
if("POST".equals(request.getMethod())&&"teacher".equals(role)){
 if("del".equals(request.getParameter("act"))){
  Map<String,String> x=Db.find("materials","id",request.getParameter("id"));
  if(x!=null&&me.get("id").equals(x.get("by"))){
   Db.dropFile(x.get("file"));
   Db.t("materials").remove(x);Db.save();
  }
  response.sendRedirect("materials.jsp");return;
 }
 String title=String.valueOf(request.getParameter("title")).trim();
 String l=String.valueOf(request.getParameter("link")).trim();
 if(title.isEmpty()||!(l.isEmpty()||l.matches("(?i)https?://.+")))err="Add a title. A link must start with http:// or https://";
 else{
  String fid="";
  try{
   fid=Db.saveFile(request.getPart("file"),me.get("id"),"material","");
  }catch(Exception ex){
   err=ex instanceof IllegalArgumentException?ex.getMessage():"Upload failed. The file must be under 5 MB.";
  }
  if(err==null){
   Db.t("materials").add(Db.row("id",Db.id(),"title",title,"subject",String.valueOf(request.getParameter("subject")).trim(),"desc",String.valueOf(request.getParameter("desc")).trim(),"link",l,"file",fid,"by",me.get("id")));
   Db.save();response.sendRedirect("materials.jsp");return;
  }
 }
}
%>
<h2>Exam material</h2>
<% if("teacher".equals(role)){%>
<form class="card" method="post" enctype="multipart/form-data"><h3>Add material</h3>
<% if(err!=null){%><p class="err"><%=Db.h(err)%></p><%}%>
<input name="title" placeholder="Title" required><input name="subject" placeholder="Subject" required><textarea name="desc" rows="3" placeholder="Notes"></textarea><input name="link" type="url" placeholder="Link (optional, https://...)">
<label>Attach a file or photo (optional, max 5 MB)<input type="file" name="file" accept="image/*,.pdf,.doc,.docx,.txt,.ppt,.pptx,.xls,.xlsx,.csv,.zip" onchange="if(this.files[0]&&this.files[0].size>5242880){alert('Maximum file size is 5 MB');this.value=''}"></label>
<button>Add material</button></form>
<% }
for(Map<String,String> x:Db.t("materials")){%>
<div class="card"><b><%=Db.h(x.get("title"))%></b> <span class="tag"><%=Db.h(x.get("subject"))%></span><p><%=Db.h(x.get("desc"))%></p>
<%=Db.fileHtml(x.get("file"))%>
<% if(!x.get("link").isEmpty()){%><p><a href="<%=Db.h(x.get("link"))%>" target="_blank" rel="noopener">Open link</a></p><%}
if("teacher".equals(role)&&me.get("id").equals(x.get("by"))){%><form method="post"><input type="hidden" name="act" value="del"><input type="hidden" name="id" value="<%=x.get("id")%>"><button class="d">Delete</button></form><%}%>
</div>
<% } %>
<%@ include file="_bot.jspf" %>
