package app;

import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.Map;

public class FileServlet extends HttpServlet {
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Map<String, String> me = Db.me(req.getSession());
        Map<String, String> f = Db.find("files", "id", req.getParameter("id"));
        if (me == null || f == null) {
            resp.sendError(404);
            return;
        }
        boolean ok = "material".equals(f.get("kind")) || "admin".equals(me.get("role")) || me.get("id").equals(f.get("owner"));
        if (!ok && "teacher".equals(me.get("role"))) {
            Map<String, String> e = Db.find("exams", "id", f.get("exam"));
            ok = e != null && me.get("id").equals(e.get("by"));
        }
        if (!ok) {
            resp.sendError(403);
            return;
        }
        byte[] data = Db.blob(f.get("id"));
        if (data == null) {
            resp.sendError(404);
            return;
        }
        String ext = f.get("ext");
        boolean img = ext.equals("jpg") || ext.equals("jpeg") || ext.equals("png") || ext.equals("gif") || ext.equals("webp");
        resp.setContentType(img ? "image/" + (ext.equals("jpg") ? "jpeg" : ext) : "application/octet-stream");
        resp.setHeader("X-Content-Type-Options", "nosniff");
        resp.setHeader("Content-Disposition", (img ? "inline" : "attachment") + "; filename=\"" + f.get("name") + "\"");
        resp.setContentLength(data.length);
        resp.getOutputStream().write(data);
    }
}
