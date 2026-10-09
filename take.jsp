<%@ include file="_top.jspf" %>
<%
Map<String,String> e=Db.find("exams","id",request.getParameter("id"));
if(e==null||!"student".equals(role)){response.sendRedirect("exams.jsp");return;}
for(Map<String,String> r:Db.t("results"))if(r.get("exam").equals(e.get("id"))&&r.get("stu").equals(me.get("id"))){response.sendRedirect("results.jsp");return;}
List<Map<String,String>> q=Db.qs(e);
String err=null;
if("POST".equals(request.getMethod())){
 List<String> a=new ArrayList<>();
 Map<String,String> fm=new LinkedHashMap<>();
 try{
  for(int i=0;i<q.size();i++){
   String t=q.get(i).get("t");
   if("multi".equals(t)){
    String[] v=request.getParameterValues("q"+i);
    a.add(v==null?"":String.join(",",v));
   }else{
    String v=request.getParameter("q"+i);
    a.add(v==null?"":v.trim());
   }
   if("long".equals(t)||"file".equals(t)){
    String fid=Db.saveFile(request.getPart("f"+i),me.get("id"),"answer",e.get("id"));
    if(!fid.isEmpty())fm.put(""+i,fid);
   }
  }
 }catch(Exception ex){
  err=ex instanceof IllegalArgumentException?ex.getMessage():"Upload failed. Each file must be under 5 MB and all files under 25 MB together.";
 }
 if(err==null){
  Db.t("results").add(Db.row("id",Db.id(),"exam",e.get("id"),"stu",me.get("id"),"a",Db.G.toJson(a),"f",Db.G.toJson(fm),"g","{}","at",new Date().toString()));
  Db.save();response.sendRedirect("results.jsp");return;
 }
 for(String fid:fm.values())Db.dropFile(fid);
}
%>
<h2><%=Db.h(e.get("title"))%></h2>
<% if(err!=null){%><p class="err"><%=Db.h(err)%> Please check your answers and submit again.</p><%}%>
<div class="clk" id="clk"></div>
<form method="post" enctype="multipart/form-data" id="f">
<% for(int i=0;i<q.size();i++){
 Map<String,String> x=q.get(i);
 String t=x.get("t");%>
<div class="card"><p><b>Q<%=i+1%>.</b> <%=Db.h(x.get("q"))%> <span class="mut">(<%=x.get("m")%> marks)</span></p>
<% if("mcq".equals(t)||"multi".equals(t)){
 boolean mu="multi".equals(t);
 if(mu){%><p class="mut sm">Select all that apply</p><%}
 for(int j=0;j<4;j++){%><label class="op<%=mu?" ck":""%>"><input type="<%=mu?"checkbox":"radio"%>" name="q<%=i%>" value="<%=j%>"> <%=Db.h(x.get("o"+j))%></label><%}
}else{
 if("long".equals(t)){%><textarea name="q<%=i%>" rows="6" placeholder="Write your answer"></textarea><%}%>
<label><%="long".equals(t)?"Attach a file or photo (optional, max 5 MB)":"Upload your file or photo (max 5 MB)"%><input type="file" name="f<%=i%>" accept="image/*,.pdf,.doc,.docx,.txt,.ppt,.pptx,.xls,.xlsx,.csv,.zip" onchange="if(this.files[0]&&this.files[0].size>5242880){alert('Maximum file size is 5 MB');this.value=''}"></label>
<% } %>
</div>
<% } %>
<button>Submit exam</button></form>
<script src="exam.js" data-minutes="<%=Db.num(e.get("dur"),15)%>"></script>
<%@ include file="_bot.jspf" %>
