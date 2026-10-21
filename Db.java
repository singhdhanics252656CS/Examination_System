package app;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import jakarta.servlet.http.HttpSession;
import jakarta.servlet.http.Part;
import java.nio.file.*;
import java.util.*;

public class Db {
    public static final Gson G = new Gson();
    static final Path F = Paths.get(System.getProperty("java.io.tmpdir"), "examhub.json");
    static Map<String, List<Map<String, String>>> d;
    static int seq = 0;
    public static final Path DIR = Paths.get(System.getProperty("java.io.tmpdir"), "examhub-files");
    static final Set<String> OK = new HashSet<>(Arrays.asList("jpg", "jpeg", "png", "gif", "webp", "pdf", "txt", "doc", "docx", "ppt", "pptx", "xls", "xlsx", "csv", "zip"));

    public static Map<String, String> row(String... kv) {
        Map<String, String> m = new LinkedHashMap<>();
        for (int i = 0; i < kv.length; i += 2) m.put(kv[i], kv[i + 1]);
        return m;
    }

    public static synchronized List<Map<String, String>> t(String n) {
        if (d == null) {
            try {
                d = G.fromJson(load(), new TypeToken<Map<String, List<Map<String, String>>>>() {}.getType());
            } catch (Exception e) {
                if (useDb() && !"empty".equals(e.getMessage())) throw new IllegalStateException("Database unavailable: " + e.getMessage());
                d = new HashMap<>();
            }
            for (String k : new String[]{"users", "exams", "results", "feedback", "materials", "files"}) d.putIfAbsent(k, new ArrayList<>());
            if (d.get("users").isEmpty()) seed();
        }
        return d.get(n);
    }

    static void seed() {
        d.get("users").add(row("id", "1", "role", "admin", "name", "Administrator", "email", "admin@examhub.com", "pass", "admin123"));
        d.get("users").add(row("id", "2", "role", "teacher", "name", "Demo Teacher", "email", "teacher@examhub.com", "pass", "teacher123"));
        d.get("users").add(row("id", "3", "role", "student", "name", "Demo Student", "email", "student@examhub.com", "pass", "student123"));
        List<Map<String, String>> q = new ArrayList<>();
        q.add(row("t", "mcq", "q", "What is the capital of France?", "o0", "Berlin", "o1", "Paris", "o2", "Rome", "o3", "Madrid", "a", "1", "m", "2"));
        q.add(row("t", "mcq", "q", "Which planet is called the Red Planet?", "o0", "Venus", "o1", "Mars", "o2", "Jupiter", "o3", "Saturn", "a", "1", "m", "2"));
        q.add(row("t", "long", "q", "Explain the water cycle in your own words.", "m", "6"));
        d.get("exams").add(row("id", "1", "title", "General Knowledge Basics", "subject", "GK", "dur", "10", "by", "2", "q", G.toJson(q)));
        d.get("materials").add(row("id", "1", "title", "How to prepare for exams", "subject", "General", "desc", "Revise in short sessions, practise past questions and sleep well before the exam.", "link", "", "by", "2"));
        save();
    }

    static boolean useDb() {
        String u = System.getenv("DATABASE_URL");
        return u != null && !u.isEmpty();
    }

    static java.sql.Connection conn() throws Exception {
        Class.forName("org.postgresql.Driver");
        java.net.URI uri = new java.net.URI(System.getenv("DATABASE_URL").replaceFirst("^postgres(ql)?://", "http://"));
        String[] ui = uri.getUserInfo().split(":", 2);
        String url = "jdbc:postgresql://" + uri.getHost() + ":" + (uri.getPort() < 0 ? 5432 : uri.getPort()) + uri.getPath() + "?sslmode=require";
        return java.sql.DriverManager.getConnection(url, ui[0], ui[1]);
    }

    static String load() throws Exception {
        if (!useDb()) return Files.readString(F);
        try (java.sql.Connection c = conn(); java.sql.Statement st = c.createStatement()) {
            st.execute("CREATE TABLE IF NOT EXISTS kv(k TEXT PRIMARY KEY, v TEXT)");
            st.execute("CREATE TABLE IF NOT EXISTS blobs(id TEXT PRIMARY KEY, b BYTEA)");
            try (java.sql.ResultSet r = st.executeQuery("SELECT v FROM kv WHERE k='data'")) {
                if (r.next()) return r.getString(1);
            }
        }
        throw new Exception("empty");
    }

    public static synchronized void save() {
        String json = G.toJson(d);
        if (useDb()) {
            try (java.sql.Connection c = conn(); java.sql.PreparedStatement p = c.prepareStatement("INSERT INTO kv(k,v) VALUES('data',?) ON CONFLICT (k) DO UPDATE SET v=EXCLUDED.v")) {
                p.setString(1, json);
                p.executeUpdate();
            } catch (Exception e) {
                throw new IllegalStateException("Could not save: " + e.getMessage());
            }
        } else {
            try {
                Files.writeString(F, json);
            } catch (Exception e) {
            }
        }
    }

    static void putBlob(String id, byte[] b) throws Exception {
        if (useDb()) {
            try (java.sql.Connection c = conn(); java.sql.PreparedStatement p = c.prepareStatement("INSERT INTO blobs(id,b) VALUES(?,?) ON CONFLICT (id) DO UPDATE SET b=EXCLUDED.b")) {
                p.setString(1, id);
                p.setBytes(2, b);
                p.executeUpdate();
            }
        } else {
            Files.createDirectories(DIR);
            Files.write(DIR.resolve(id), b);
        }
    }

    public static byte[] blob(String id) {
        try {
            if (useDb()) {
                try (java.sql.Connection c = conn(); java.sql.PreparedStatement p = c.prepareStatement("SELECT b FROM blobs WHERE id=?")) {
                    p.setString(1, id);
                    try (java.sql.ResultSet r = p.executeQuery()) {
                        return r.next() ? r.getBytes(1) : null;
                    }
                }
            }
            Path f = DIR.resolve(id);
            return Files.exists(f) ? Files.readAllBytes(f) : null;
        } catch (Exception e) {
            return null;
        }
    }

    static void delBlob(String id) {
        try {
            if (useDb()) {
                try (java.sql.Connection c = conn(); java.sql.PreparedStatement p = c.prepareStatement("DELETE FROM blobs WHERE id=?")) {
                    p.setString(1, id);
                    p.executeUpdate();
                }
            } else {
                Files.deleteIfExists(DIR.resolve(id));
            }
        } catch (Exception e) {
        }
    }

    public static synchronized String id() {
        return System.currentTimeMillis() + "" + (seq++ % 10);
    }

    public static Map<String, String> find(String table, String key, String val) {
        if (val == null) return null;
        for (Map<String, String> r : t(table)) if (val.equals(r.get(key))) return r;
        return null;
    }

    public static Map<String, String> me(HttpSession s) {
        Object i = s.getAttribute("uid");
        return i == null ? null : find("users", "id", "" + i);
    }

    public static String name(String uid) {
        Map<String, String> u = find("users", "id", uid);
        return u == null ? "Unknown" : u.get("name");
    }

    public static String h(String s) {
        return s == null ? "" : s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }

    public static int num(String s, int def) {
        try {
            return Integer.parseInt(s.trim());
        } catch (Exception e) {
            return def;
        }
    }

    public static List<Map<String, String>> qs(Map<String, String> e) {
        return G.fromJson(e.get("q"), new TypeToken<List<Map<String, String>>>() {}.getType());
    }

    public static List<String> answers(Map<String, String> r) {
        return G.fromJson(r.get("a"), new TypeToken<List<String>>() {}.getType());
    }

    public static Map<String, String> grades(Map<String, String> r) {
        return G.fromJson(r.get("g"), new TypeToken<Map<String, String>>() {}.getType());
    }

    public static Map<String, String> files(Map<String, String> r) {
        String s = r.get("f");
        if (s == null) return new HashMap<>();
        return G.fromJson(s, new TypeToken<Map<String, String>>() {}.getType());
    }

    static boolean same(String x, String y) {
        if (y == null) return false;
        Set<String> a = new TreeSet<>(Arrays.asList(x.split(",")));
        Set<String> b = new TreeSet<>();
        for (String v : y.split(",")) if (!v.trim().isEmpty()) b.add(v.trim());
        return a.equals(b);
    }

    public static int[] score(Map<String, String> r) {
        Map<String, String> e = find("exams", "id", r.get("exam"));
        if (e == null) return new int[]{0, 0, 0};
        List<Map<String, String>> q = qs(e);
        List<String> a = answers(r);
        Map<String, String> g = grades(r);
        int got = 0, tot = 0, pend = 0;
        for (int i = 0; i < q.size(); i++) {
            String t = q.get(i).get("t");
            int m = num(q.get(i).get("m"), 1);
            tot += m;
            if ("mcq".equals(t) || "multi".equals(t)) {
                if (i < a.size() && same(q.get(i).get("a"), a.get(i))) got += m;
            } else if (g.containsKey("" + i)) got += num(g.get("" + i), 0);
            else pend = 1;
        }
        return new int[]{got, tot, pend};
    }

    public static List<Map<String, String>> cleanQs(String json) {
        List<Map<String, String>> out = new ArrayList<>();
        try {
            List<Map<String, String>> in = G.fromJson(json, new TypeToken<List<Map<String, String>>>() {}.getType());
            for (Map<String, String> x : in) {
                String t = String.valueOf(x.get("t")), q = String.valueOf(x.get("q")).trim();
                int m = Math.max(1, Math.min(100, num(x.get("m"), 1)));
                if (q.isEmpty() || q.equals("null")) continue;
                Map<String, String> o = row("t", t, "q", q, "m", "" + m);
                if (t.equals("mcq") || t.equals("multi")) {
                    boolean bad = false;
                    for (int i = 0; i < 4; i++) {
                        String v = String.valueOf(x.get("o" + i)).trim();
                        if (v.isEmpty() || v.equals("null")) bad = true;
                        o.put("o" + i, v);
                    }
                    TreeSet<String> sel = new TreeSet<>();
                    for (String p : String.valueOf(x.get("a")).split(",")) if (p.trim().matches("[0-3]")) sel.add(p.trim());
                    if (bad || sel.isEmpty() || (t.equals("mcq") && sel.size() != 1)) continue;
                    o.put("a", String.join(",", sel));
                } else if (!t.equals("long") && !t.equals("file")) continue;
                out.add(o);
            }
        } catch (Exception e) {
        }
        return out;
    }

    public static String saveFile(Part p, String owner, String kind, String exam) {
        try {
            if (p == null || p.getSize() == 0) return "";
            if (p.getSize() > 5L * 1024 * 1024) throw new IllegalArgumentException("A file is larger than 5 MB.");
            String name = Paths.get(String.valueOf(p.getSubmittedFileName())).getFileName().toString().replaceAll("[^A-Za-z0-9._ -]", "_");
            int dot = name.lastIndexOf('.');
            String ext = dot < 0 ? "" : name.substring(dot + 1).toLowerCase();
            if (!OK.contains(ext)) throw new IllegalArgumentException("This file type is not allowed. Use a photo, PDF, Word, PowerPoint, Excel, text or zip file.");
            String id = id();
            try (java.io.InputStream in = p.getInputStream()) {
                putBlob(id, in.readAllBytes());
            }
            t("files").add(row("id", id, "name", name, "ext", ext, "owner", owner, "kind", kind, "exam", exam));
            save();
            return id;
        } catch (IllegalArgumentException e) {
            throw e;
        } catch (Exception e) {
            throw new IllegalStateException("Could not save the file.");
        }
    }

    public static void dropFile(String fid) {
        Map<String, String> f = find("files", "id", fid);
        if (f == null) return;
        t("files").remove(f);
        delBlob(fid);
    }

    public static void dropFilesWhere(String key, String val) {
        for (Map<String, String> f : new ArrayList<>(t("files"))) if (val.equals(f.get(key))) dropFile(f.get("id"));
    }

    public static String fileHtml(String fid) {
        Map<String, String> f = find("files", "id", fid);
        if (f == null) return "";
        String ext = f.get("ext"), nm = h(f.get("name"));
        boolean img = ext.equals("jpg") || ext.equals("jpeg") || ext.equals("png") || ext.equals("gif") || ext.equals("webp");
        String url = "f?id=" + f.get("id");
        return (img ? "<img class=\"pic\" src=\"" + url + "\" alt=\"" + nm + "\"><br>" : "") + "<a href=\"" + url + "\">" + (img ? "Open photo: " : "Download: ") + nm + "</a>";
    }
}
