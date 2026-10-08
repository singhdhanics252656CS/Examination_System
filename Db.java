package app;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import jakarta.servlet.http.HttpSession;
import java.nio.file.*;
import java.util.*;

public class Db {
    public static final Gson G = new Gson();
    static final Path F = Paths.get(System.getProperty("java.io.tmpdir"), "examhub.json");
    static Map<String, List<Map<String, String>>> d;
    static int seq = 0;

    public static Map<String, String> row(String... kv) {
        Map<String, String> m = new LinkedHashMap<>();
        for (int i = 0; i < kv.length; i += 2) m.put(kv[i], kv[i + 1]);
        return m;
    }

    public static synchronized List<Map<String, String>> t(String n) {
        if (d == null) {
            try {
                d = G.fromJson(Files.readString(F), new TypeToken<Map<String, List<Map<String, String>>>>() {}.getType());
            } catch (Exception e) {
                d = new HashMap<>();
            }
            for (String k : new String[]{"users", "exams", "results", "feedback", "materials"}) d.putIfAbsent(k, new ArrayList<>());
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

    public static synchronized void save() {
        try {
            Files.writeString(F, G.toJson(d));
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

    public static int[] score(Map<String, String> r) {
        Map<String, String> e = find("exams", "id", r.get("exam"));
        if (e == null) return new int[]{0, 0, 0};
        List<Map<String, String>> q = qs(e);
        List<String> a = answers(r);
        Map<String, String> g = grades(r);
        int got = 0, tot = 0, pend = 0;
        for (int i = 0; i < q.size(); i++) {
            int m = num(q.get(i).get("m"), 1);
            tot += m;
            if ("mcq".equals(q.get(i).get("t"))) {
                if (i < a.size() && q.get(i).get("a").equals(a.get(i))) got += m;
            } else if (g.containsKey("" + i)) got += num(g.get("" + i), 0);
            else pend = 1;
        }
        return new int[]{got, tot, pend};
    }
}
