import streamlit as st
import pandas as pd
from datetime import date
from db import Database
import time
import sys

st.set_page_config(page_title="Attractions DB", page_icon="🌍", layout="wide", initial_sidebar_state="expanded")

# --- Custom CSS ---
st.markdown("""
<style>
    body { font-family: 'Inter', sans-serif; background-color: #F8FAFC; color: #1E293B; }
    [data-testid="stSidebar"] div[role="radiogroup"] > label > div:first-child { display: none; }
    [data-testid="stSidebar"] div[role="radiogroup"] label { padding: 10px; border-radius: 8px; transition: background 0.2s; }
    [data-testid="stSidebar"] div[role="radiogroup"] label:hover { background-color: #E2E8F0; }
    
    .stat-card {
        background-color: white; border-radius: 12px; padding: 20px;
        box-shadow: 0 1px 3px rgba(0,0,0,0.1); border: 1px solid #E2E8F0; text-align: center;
    }
    .stat-value { font-size: 32px; font-weight: 700; color: #0F766E; }
    .stat-label { font-size: 14px; color: #64748B; text-transform: uppercase; letter-spacing: 1px; }
    
    .stDataFrame { border-radius: 8px; overflow: hidden; border: 1px solid #E2E8F0; }
</style>
""", unsafe_allow_html=True)

@st.cache_resource
def get_db():
    return Database()

try:
    db = get_db()
    # Check if DB is actually available
    with db.connect() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT 1")
except Exception as e:
    print(f"FATAL: Database connection failed. Exception: {e}", file=sys.stderr)
    st.error("Database is not available. Please run `docker-compose up -d` in your terminal.")
    st.stop()

# --- Helpers ---
def friendly_error(e):
    err_str = str(e).lower()
    print(f"DATABASE EXCEPTION: {e}", file=sys.stderr)
    if "foreign key constraint" in err_str or "violates foreign key" in err_str: 
        return "Cannot delete or update this record because related records exist."
    if "unique constraint" in err_str: return "This value already exists."
    if "does not exist" in err_str: return "A database table, column, or function is missing. Please check the schema mapping."
    if "chk_" in err_str or "check constraint" in err_str: return "The selected value is not allowed by the database (Check Constraint failed)."
    return f"Database Error: {e}"

def run_query(q, params=None):
    try:
        return db.fetchall(q, params)
    except Exception as e:
        st.error(friendly_error(e))
        return []

def run_exec(q, params=None):
    try:
        db.execute(q, params)
        return True
    except Exception as e:
        st.error(friendly_error(e))
        return False

def get_next_id(table, pk_col):
    res = run_query(f'SELECT COALESCE(MAX("{pk_col}"), 0) + 1 AS next_id FROM "{table}"')
    if res and res[0] and res[0].get('next_id'):
        return res[0]['next_id']
    return 1

def trigger_check(table, pk_col, pk_val, track_col):
    res = run_query(f'SELECT "{track_col}" FROM "{table}" WHERE "{pk_col}" = %s', [int(pk_val)])
    if res and res[0] and res[0].get(track_col) is not None:
        return float(res[0][track_col])
    return None

# --- Session State ---
if 'current_user_id' not in st.session_state:
    st.session_state.current_user_id = 1
if 'nav_selection' not in st.session_state:
    st.session_state.nav_selection = "🏠 Dashboard"

# --- Top Bar ---
users = run_query("SELECT customer_id, full_name FROM customer ORDER BY customer_id")
user_opts = {u['customer_id']: u['full_name'] for u in users}

t1, t2 = st.columns([8, 2])
with t2:
    if user_opts:
        idx = 0
        if st.session_state.current_user_id in user_opts: 
            idx = list(user_opts.keys()).index(st.session_state.current_user_id)
        selected_u = st.selectbox("Current User", options=list(user_opts.keys()), format_func=lambda x: f"👩 {user_opts[x]} · {x}", index=idx)
        if selected_u != st.session_state.current_user_id:
            st.session_state.current_user_id = selected_u
            st.rerun()
    else:
        st.warning("No customers available")

# --- Sidebar ---
st.sidebar.markdown("<h2 style='text-align: center; color: #0F766E;'>Attractions DB</h2><hr/>", unsafe_allow_html=True)

app_mode = st.sidebar.radio("Navigation", [
    "🏠 Dashboard",
    "📊 Analytics & Reports",
    "⭐ Reviews",
    "🛡️ Moderation",
    "🎟️ Tickets",
    "👤 Customers",
    "🏞️ Attractions",
    "🗄️ Table Manager",
    "⚙️ Database Programs"
], key="nav_selection", label_visibility="collapsed")

# ---------------------------------------------------------
# 1. Dashboard
# ---------------------------------------------------------
if app_mode == "🏠 Dashboard":
    st.title("Welcome to Attractions DB")
    st.write("Overview of the system data and quick actions.")
    
    tables = [
        ("Attractions", "attraction", "🏞️"),
        ("Customers", "customer", "👥"),
        ("Tickets", "ticket", "🎟️"),
        ("Reviews", "review", "⭐"),
        ("Bookings", "booking", "📅")
    ]
    cols = st.columns(5)
    for i, (title, table, icon) in enumerate(tables):
        try:
            count = run_query(f'SELECT COUNT(*) as cnt FROM "{table}"')
            val = count[0]['cnt'] if count else 0
        except:
            val = 0
        cols[i].markdown(f"""
        <div class="stat-card">
            <div style="font-size: 24px; margin-bottom: 10px;">{icon}</div>
            <div class="stat-value">{val:,}</div>
            <div class="stat-label">{title}</div>
        </div>
        """, unsafe_allow_html=True)


# ---------------------------------------------------------
# 2. Analytics & Reports
# ---------------------------------------------------------
elif app_mode == "📊 Analytics & Reports":
    st.title("Analytics & Reports")
    report_type = st.radio("Select Report", ["Attraction Overview", "Booking Summary", "Review Details"], horizontal=True)
    
    def safe_render(data, hide_ids=True):
        if not data: return pd.DataFrame()
        df = pd.DataFrame(data)
        if hide_ids:
            cols_to_drop = [c for c in df.columns if c.lower().endswith('_id') or c.lower() == 'id']
            df = df.drop(columns=cols_to_drop, errors='ignore')
        # Fix pyarrow serialization bug with Postgres Decimals/UUIDs
        for c in df.columns:
            if df[c].dtype == 'object':
                try: df[c] = pd.to_numeric(df[c])
                except: df[c] = df[c].astype(str)
        return df

    if report_type == "Attraction Overview":
        st.write("### Top Attractions Overview")
        data = run_query("SELECT * FROM view_attraction_overview ORDER BY calculated_avg_rating DESC NULLS LAST")
        if data: st.dataframe(safe_render(data), use_container_width=True, key="df_attractions")
        else: st.warning("View 'view_attraction_overview' is missing or empty.")
            
    elif report_type == "Booking Summary":
        st.write("### Booking Summary Report")
        data = run_query("SELECT * FROM view_booking_summary ORDER BY booking_date DESC")
        if data: st.dataframe(safe_render(data), use_container_width=True, key="df_bookings")
        else: st.warning("View 'view_booking_summary' is missing or empty.")
            
    elif report_type == "Review Details":
        st.write("### Review Details Report")
        data = run_query("SELECT * FROM view_review_details ORDER BY review_date DESC")
        if data: st.dataframe(safe_render(data), use_container_width=True, key="df_reviews")
        else: st.warning("View 'view_review_details' is missing or empty.")

# ---------------------------------------------------------
# 3. Reviews
# ---------------------------------------------------------
elif app_mode == "⭐ Reviews":
    st.title("Reviews Management")
    c1, c2 = st.columns([6, 4])
    
    with c1:
        st.subheader("All Reviews")
        reviews = run_query("""
            SELECT r.review_id AS db_id, r.review_id AS "#", c.full_name AS "Customer", a.attraction_name AS "Attraction", r.rating AS "Rating", r.title AS "Title", r.review_date AS "Date", COALESCE(r.is_deleted, false) AS "Deleted"
            FROM review r
            LEFT JOIN ticket t ON r.ticket_id = t.ticket_id
            LEFT JOIN customer c ON t.customer_id = c.customer_id OR r.direct_customer_id = c.customer_id
            LEFT JOIN attraction a ON t.attraction_id = a.attraction_id OR r.direct_attraction_id = a.attraction_id
            ORDER BY r.review_id ASC
        """)
        if reviews:
            df = pd.DataFrame(reviews)
            
            with st.expander("🔍 Filters", expanded=False):
                f1, f2, f3 = st.columns(3)
                f_cust = f1.text_input("Customer Name", key="rev_fcust")
                f_att = f2.text_input("Attraction", key="rev_fatt")
                f_title = f3.text_input("Title", key="rev_ftitle")
                f_stat = st.selectbox("Status", ["All", "Active Only", "Deleted Only"], key="rev_fstat")
                
                if f_cust: df = df[df["Customer"].astype(str).str.contains(f_cust, case=False, na=False)]
                if f_att: df = df[df["Attraction"].astype(str).str.contains(f_att, case=False, na=False)]
                if f_title: df = df[df["Title"].astype(str).str.contains(f_title, case=False, na=False)]
                if f_stat == "Active Only": df = df[df["Deleted"] == False]
                elif f_stat == "Deleted Only": df = df[df["Deleted"] == True]
            
            df['#'] = range(1, len(df)+1)
            event = st.dataframe(df.drop(columns=['db_id', 'Deleted']), selection_mode="single-row", on_select="rerun", use_container_width=True, hide_index=True)
            sel_idx = event.selection.rows[0] if event.selection.rows else None
        else:
            st.info("No reviews found.")
            sel_idx = None
            
        with st.expander("➕ Add Review"):
            with st.form("add_review"):
                curr_user = st.session_state.current_user_id
                tks = run_query("SELECT t.ticket_id, t.attraction_id, a.attraction_name FROM ticket t JOIN attraction a ON t.attraction_id = a.attraction_id WHERE t.customer_id = %s", [curr_user])
                tk_opts = {t['ticket_id']: f"Ticket {t['ticket_id']} - {t['attraction_name']}" for t in tks}
                if tk_opts:
                    t_id = st.selectbox("Select Ticket", list(tk_opts.keys()), format_func=lambda x: tk_opts[x])
                else:
                    t_id = None
                    st.warning("Current user has no tickets. Cannot link review to ticket.")
                    
                st.write("Rating")
                r_rating = st.radio("Rating", ["⭐", "⭐⭐", "⭐⭐⭐", "⭐⭐⭐⭐", "⭐⭐⭐⭐⭐"], index=4, horizontal=True, label_visibility="collapsed")
                r_val = len(r_rating)
                
                r_title = st.text_input("Title")
                r_content = st.text_area("Content")
                r_date = st.date_input("Date", value=date.today())
                
                if st.form_submit_button("Add Review"):
                    if not r_title or not r_content:
                        st.error("Title and content are required.")
                    elif not t_id:
                        st.error("Cannot add review without a ticket.")
                    else:
                        attraction_id_for_trigger = next((t['attraction_id'] for t in tks if t['ticket_id'] == t_id), None)
                        if attraction_id_for_trigger:
                            before_rating = trigger_check('attraction', 'attraction_id', attraction_id_for_trigger, 'avg_rating')
                        else: before_rating = None
                        
                        new_id = get_next_id('review', 'review_id')
                        if run_exec("INSERT INTO review (review_id, ticket_id, direct_customer_id, rating, title, content, review_date, is_deleted) VALUES (%s, %s, %s, %s, %s, %s, %s, false)", 
                                    [new_id, int(t_id), curr_user if not t_id else None, r_val, r_title, r_content, r_date]):
                            st.success("Review added successfully.")
                            
                            # Check Trigger
                            if attraction_id_for_trigger:
                                after_rating = trigger_check('attraction', 'attraction_id', attraction_id_for_trigger, 'avg_rating')
                                if after_rating is not None and before_rating is not None and after_rating != before_rating:
                                    st.info(f"Average rating was updated automatically by trigger. (Before: {before_rating:.2f}, After: {after_rating:.2f})")
                                else:
                                    st.warning("Trigger for average rating update is not installed or did not change the rating.")
                                time.sleep(2)
                            st.rerun()

    with c2:
        st.subheader("Review Details")
        if sel_idx is not None:
            rev_id = int(df.iloc[sel_idx]['db_id'])
            rd = run_query("""
                SELECT r.*, c.full_name, c.avatar_url, a.attraction_name,
                (SELECT COUNT(*) FROM reviewreaction WHERE review_id = r.review_id AND reaction_type = 'like') as likes_count,
                (SELECT COUNT(*) FROM reviewreaction WHERE review_id = r.review_id AND reaction_type = 'dislike') as dislikes_count,
                (SELECT COUNT(*) FROM reviewreport WHERE review_id = r.review_id) as reports_count
                FROM review r
                LEFT JOIN ticket t ON r.ticket_id = t.ticket_id
                LEFT JOIN customer c ON t.customer_id = c.customer_id OR r.direct_customer_id = c.customer_id
                LEFT JOIN attraction a ON t.attraction_id = a.attraction_id OR r.direct_attraction_id = a.attraction_id
                WHERE r.review_id = %s
            """, [rev_id])
            if rd:
                r = rd[0]
                av = r.get('avatar_url') or f"https://ui-avatars.com/api/?name={r.get('full_name','User').replace(' ','+')}&background=0F766E&color=fff"
                rating_num = int(r.get('rating') or 0)
                stars_str = '⭐' * rating_num
                
                st.markdown(f"""
                <div style="background: white; padding: 20px; border-radius: 12px; border: 1px solid #E2E8F0;">
                    <div style="display: flex; align-items: center; margin-bottom: 15px;">
                        <img src="{av}" style="width: 40px; height: 40px; border-radius: 50%; margin-right: 15px;">
                        <div>
                            <div style="font-weight: bold;">{r.get('full_name', 'Unknown Customer')}</div>
                            <div style="font-size: 12px; color: #64748B;">{r.get('review_date')}</div>
                        </div>
                    </div>
                    <div style="color: #0F766E; font-weight: bold; margin-bottom: 5px;">{r.get('attraction_name', 'Unknown Attraction')} - {stars_str}</div>
                    <div style="font-weight: bold; font-size: 18px; margin-bottom: 10px;">{r.get('title', '')}</div>
                    <div style="color: #334155; margin-bottom: 15px;">{r.get('content', '')}</div>
                    <div style="display: flex; gap: 15px; font-size: 13px; color: #64748B;">
                        <span>👍 {r.get('likes_count', 0)}</span>
                        <span>👎 {r.get('dislikes_count', 0)}</span>
                        <span>🚩 {r.get('reports_count', 0)} Reports</span>
                        <span>| Status: {'🔴 Deleted' if r.get('is_deleted') else '🟢 Active'}</span>
                    </div>
                </div>
                """, unsafe_allow_html=True)
                
                # Edit Review
                with st.expander("✏️ Edit Review"):
                    with st.form("edit_review_form"):
                        opts = ["⭐", "⭐⭐", "⭐⭐⭐", "⭐⭐⭐⭐", "⭐⭐⭐⭐⭐"]
                        try:
                            idx = rating_num - 1
                            if idx < 0: idx = 0
                        except: idx = 4
                        
                        st.write("Rating")
                        e_rating = st.radio("Edit Rating", opts, index=idx, horizontal=True, label_visibility="collapsed")
                        e_val = len(e_rating)
                        
                        e_title = st.text_input("Title", value=r.get('title', ''))
                        e_content = st.text_area("Content", value=r.get('content', ''))
                        if st.form_submit_button("Save Changes"):
                            if run_exec("UPDATE review SET rating=%s, title=%s, content=%s WHERE review_id=%s", [e_val, e_title, e_content, rev_id]):
                                st.success("Review updated successfully.")
                                time.sleep(1)
                                st.rerun()

                # Actions
                st.write("### Actions")
                b1, b2, b3 = st.columns(3)
                
                curr_user = st.session_state.current_user_id
                my_reaction = run_query("SELECT reaction_type FROM reviewreaction WHERE review_id = %s AND customer_id = %s", [rev_id, curr_user])
                my_rt = my_reaction[0]['reaction_type'] if my_reaction else None
                
                like_lbl = "👍 Liked" if my_rt == 'like' else "👍 Like"
                dislike_lbl = "👎 Disliked" if my_rt == 'dislike' else "👎 Dislike"
                
                if b1.button(like_lbl, key=f"like_review_{rev_id}", use_container_width=True):
                    if my_rt == 'like':
                        if run_exec("DELETE FROM reviewreaction WHERE review_id = %s AND customer_id = %s", [rev_id, curr_user]):
                            st.toast("Like removed.")
                    elif my_rt == 'dislike':
                        if run_exec("UPDATE reviewreaction SET reaction_type = 'like', reaction_date = CURRENT_DATE WHERE review_id = %s AND customer_id = %s", [rev_id, curr_user]):
                            st.toast("Reaction changed to Like.")
                    else:
                        run_exec("DELETE FROM reviewreaction WHERE review_id = %s AND customer_id = %s", [rev_id, curr_user])
                        new_rx_id = get_next_id('reviewreaction', 'reaction_id')
                        if run_exec("INSERT INTO reviewreaction (reaction_id, reaction_type, reaction_date, review_id, customer_id) VALUES (%s, 'like', CURRENT_DATE, %s, %s)", [new_rx_id, rev_id, curr_user]):
                            st.toast("Like added.")
                    time.sleep(1)
                    st.rerun()
                    
                if b2.button(dislike_lbl, key=f"dislike_review_{rev_id}", use_container_width=True):
                    if my_rt == 'dislike':
                        if run_exec("DELETE FROM reviewreaction WHERE review_id = %s AND customer_id = %s", [rev_id, curr_user]):
                            st.toast("Dislike removed.")
                    elif my_rt == 'like':
                        if run_exec("UPDATE reviewreaction SET reaction_type = 'dislike', reaction_date = CURRENT_DATE WHERE review_id = %s AND customer_id = %s", [rev_id, curr_user]):
                            st.toast("Reaction changed to Dislike.")
                    else:
                        run_exec("DELETE FROM reviewreaction WHERE review_id = %s AND customer_id = %s", [rev_id, curr_user])
                        new_rx_id = get_next_id('reviewreaction', 'reaction_id')
                        if run_exec("INSERT INTO reviewreaction (reaction_id, reaction_type, reaction_date, review_id, customer_id) VALUES (%s, 'dislike', CURRENT_DATE, %s, %s)", [new_rx_id, rev_id, curr_user]):
                            st.toast("Dislike added.")
                    time.sleep(1)
                    st.rerun()
                    
                with st.form("soft_del"):
                    is_del = bool(r.get('is_deleted'))
                    if st.form_submit_button("🗑️ Soft Delete Review" if not is_del else "Status: Deleted", use_container_width=True, disabled=is_del):
                        if run_exec("UPDATE review SET is_deleted = true, deleted_date = CURRENT_DATE WHERE review_id = %s", [rev_id]):
                            st.success("Review soft deleted successfully.")
                            time.sleep(1)
                            st.rerun()
                
                with st.expander("🚩 Report this Review"):
                    with st.form("report_form"):
                        st.write(f"Reporting as User ID {curr_user}")
                        reason = st.selectbox("Reason", ["Spam", "Offensive language", "Misleading information", "Irrelevant content", "Harassment", "Other"])
                        desc = st.text_area("Note (Optional)")
                        if st.form_submit_button("Submit Report"):
                            # Check if already reported
                            exists = run_query("SELECT 1 FROM reviewreport WHERE review_id = %s AND customer_id = %s", [rev_id, curr_user])
                            if exists:
                                st.warning("You have already reported this review.")
                            else:
                                new_rp_id = get_next_id('reviewreport', 'report_id')
                                sql = "INSERT INTO reviewreport (report_id, report_reason, report_description, report_date, customer_id, review_id) VALUES (%s, %s, %s, CURRENT_DATE, %s, %s)"
                                if run_exec(sql, [new_rp_id, reason, desc, curr_user, rev_id]):
                                    st.success("Report submitted successfully.")
                                    time.sleep(1)
                                    st.rerun()
        else:
            st.info("Select a review from the table to view details.")

# ---------------------------------------------------------
# 4. Moderation
# ---------------------------------------------------------
elif app_mode == "🛡️ Moderation":
    st.title("Moderation (Reported Reviews)")
    c1, c2 = st.columns([5, 5])
    
    with c1:
        reps = run_query("""
            SELECT rp.report_id AS db_id, rp.report_id AS "#", rp.report_reason AS "Reason", rp.report_date AS "Date", c.full_name AS "Reporter", 
                   (CASE WHEN rv.is_deleted = true THEN 'Deleted' ELSE 'Active' END) AS "Review Status"
            FROM reviewreport rp
            JOIN customer c ON rp.customer_id = c.customer_id
            JOIN review rv ON rp.review_id = rv.review_id
            ORDER BY rp.report_id ASC
        """)
        if reps:
            df = pd.DataFrame(reps)
            
            with st.expander("🔍 Filters", expanded=False):
                f_rs = st.text_input("Reason", key="mod_freas")
                f_rep = st.text_input("Reporter", key="mod_frep")
                f_stat = st.selectbox("Review Status", ["All", "Active", "Deleted"], key="mod_fstat")
                if f_rs: df = df[df["Reason"].astype(str).str.contains(f_rs, case=False, na=False)]
                if f_rep: df = df[df["Reporter"].astype(str).str.contains(f_rep, case=False, na=False)]
                if f_stat != "All": df = df[df["Review Status"] == f_stat]
                
            df['#'] = range(1, len(df)+1)
            event = st.dataframe(df.drop(columns=['db_id']), selection_mode="single-row", on_select="rerun", use_container_width=True, hide_index=True)
            sel_idx = event.selection.rows[0] if event.selection.rows else None
        else:
            st.success("No pending reports.")
            sel_idx = None
            
        with st.expander("➕ Add Report Manually"):
            with st.form("add_rep_manually"):
                all_revs = run_query("SELECT review_id, title FROM review WHERE is_deleted=false OR is_deleted IS NULL")
                r_opts = {r['review_id']: f"[{r['review_id']}] {r['title']}" for r in all_revs}
                sel_rev = st.selectbox("Select Review", list(r_opts.keys()), format_func=lambda x: r_opts[x]) if r_opts else None
                reason = st.selectbox("Reason", ["Spam", "Offensive language", "Misleading information", "Irrelevant content", "Harassment", "Other"])
                desc = st.text_area("Note (Optional)")
                
                if st.form_submit_button("Add Report"):
                    if not sel_rev: st.error("No review selected.")
                    else:
                        new_id = get_next_id('reviewreport', 'report_id')
                        if run_exec("INSERT INTO reviewreport (report_id, report_reason, report_description, report_date, customer_id, review_id) VALUES (%s, %s, %s, CURRENT_DATE, %s, %s)", [new_id, reason, desc, st.session_state.current_user_id, int(sel_rev)]):
                            st.success("Report submitted successfully.")
                            time.sleep(1)
                            st.rerun()

    with c2:
        if sel_idx is not None:
            rep_id = int(df.iloc[sel_idx]['db_id'])
            rd = run_query("""
                SELECT rp.*, c.full_name AS reporter_name, r.title, r.content, r.is_deleted, a.attraction_name
                FROM reviewreport rp
                JOIN customer c ON rp.customer_id = c.customer_id
                JOIN review r ON rp.review_id = r.review_id
                LEFT JOIN ticket t ON r.ticket_id = t.ticket_id
                LEFT JOIN attraction a ON t.attraction_id = a.attraction_id OR r.direct_attraction_id = a.attraction_id
                WHERE rp.report_id = %s
            """, [rep_id])
            if rd:
                r = rd[0]
                st.write("### Report Details")
                st.write(f"**Report ID:** {r.get('report_id')}")
                st.write(f"**Reason:** {r.get('report_reason')} | **Date:** {r.get('report_date')}")
                st.write(f"**Reporter:** {r.get('reporter_name')}")
                st.write(f"**Note:** {r.get('report_description') or '---'}")
                st.markdown("---")
                
                with st.expander("✏️ Edit Report"):
                    with st.form("edit_rep"):
                        opts = ["Spam", "Offensive language", "Misleading information", "Irrelevant content", "Harassment", "Other"]
                        try: idx = opts.index(r.get('report_reason'))
                        except: idx = 5
                        new_reason = st.selectbox("Reason", opts, index=idx)
                        new_desc = st.text_area("Note", value=r.get('report_description') or '')
                        if st.form_submit_button("Save Changes"):
                            if run_exec("UPDATE reviewreport SET report_reason=%s, report_description=%s WHERE report_id=%s", [new_reason, new_desc, rep_id]):
                                st.success("Report updated successfully.")
                                time.sleep(1)
                                st.rerun()

                st.write("### Related Review")
                st.write(f"**Review ID:** {r.get('review_id')}")
                st.write(f"**Attraction:** {r.get('attraction_name', 'N/A')}")
                st.write(f"**Title:** {r.get('title')}")
                st.info(f"\"{r.get('content')}\"")
                is_del = bool(r.get('is_deleted'))
                status = "Deleted" if is_del else "Active"
                st.write(f"**Status:** {status}")
                
                col1, col2 = st.columns(2)
                with col1:
                    with st.form("del_rev_form"):
                        if st.form_submit_button("🗑️ Soft Delete Review", use_container_width=True, disabled=is_del):
                            if run_exec("UPDATE review SET is_deleted = true, deleted_date = CURRENT_DATE WHERE review_id = %s", [int(r['review_id'])]):
                                st.success("Reported review was soft deleted successfully.")
                                time.sleep(1)
                                st.rerun()
                with col2:
                    with st.form("dism_rep_form"):
                        if st.form_submit_button("✅ Dismiss Report", use_container_width=True):
                            cols = [c['column_name'] for c in db.get_columns('reviewreport')]
                            if 'admin_decision' in cols:
                                if run_exec("UPDATE reviewreport SET admin_decision = 'Dismissed', decision_date = CURRENT_DATE WHERE report_id = %s", [rep_id]):
                                    st.success("Report dismissed successfully.")
                                    time.sleep(1)
                                    st.rerun()
                            else:
                                if run_exec("DELETE FROM reviewreport WHERE report_id = %s", [rep_id]):
                                    st.success("Report dismissed successfully.")
                                    time.sleep(1)
                                    st.rerun()

# ---------------------------------------------------------
# 5. Tickets
# ---------------------------------------------------------
elif app_mode == "🎟️ Tickets":
    st.title("Tickets Management")
    c1, c2 = st.columns([6, 4])
    
    with c1:
        st.subheader("All Tickets")
        tks = run_query("""
            SELECT t.ticket_id AS db_id, t.ticket_id AS "#", c.full_name AS "Customer", a.attraction_name AS "Attraction", t.visit_date AS "Visit Date", t.ticket_status AS "Status", t.price AS "Price"
            FROM ticket t
            JOIN customer c ON t.customer_id = c.customer_id
            JOIN attraction a ON t.attraction_id = a.attraction_id
            ORDER BY t.ticket_id ASC
        """)
        if tks:
            df = pd.DataFrame(tks)
            
            with st.expander("🔍 Filters", expanded=False):
                f_cust = st.text_input("Customer Name", key="tk_fcust")
                f_att = st.text_input("Attraction", key="tk_fatt")
                f_stat = st.selectbox("Status", ["All", "active", "used", "cancelled"], key="tk_fstat")
                if f_cust: df = df[df["Customer"].astype(str).str.contains(f_cust, case=False, na=False)]
                if f_att: df = df[df["Attraction"].astype(str).str.contains(f_att, case=False, na=False)]
                if f_stat != "All": df = df[df["Status"] == f_stat]
                
            df['#'] = range(1, len(df)+1)
            event = st.dataframe(df.drop(columns=['db_id']), selection_mode="single-row", on_select="rerun", use_container_width=True, hide_index=True)
            sel_idx = event.selection.rows[0] if event.selection.rows else None
        else:
            st.info("No tickets found.")
            sel_idx = None
            
        with st.expander("➕ Add Ticket"):
            curr_user = st.session_state.current_user_id
            curr_user_name = user_opts.get(curr_user, 'Unknown')
            st.info(f"Ticket will be created for: **{curr_user_name}**")
            
            attrs = run_query("SELECT attraction_id, attraction_name, price_per_person FROM attraction")
            a_opt = {a['attraction_id']: f"{a['attraction_name']}" for a in attrs}
            
            # Selectbox is OUTSIDE the form so it triggers an immediate page rerun when changed
            sel_a = st.selectbox("Select Attraction", list(a_opt.keys()), format_func=lambda x: a_opt[x], index=None, placeholder="Choose attraction...")
            
            # Load price from attraction
            price_map = {a['attraction_id']: a.get('price_per_person') for a in attrs}
            def_price = 0.0
            if sel_a:
                raw_price = price_map.get(sel_a)
                if raw_price is None or float(raw_price) == 0.0:
                    st.warning("Selected attraction has no price configured (NULL or 0.0).")
                    def_price = 0.0
                else:
                    def_price = float(raw_price)
            
            with st.form("add_ticket_form"):
                v_date = st.date_input("Visit Date")
                
                # Price read-only
                st.number_input("Price (₪)", min_value=0.0, value=def_price, step=1.0, disabled=True)
                st.caption("Price is automatically loaded from the selected attraction.")
                
                # Status read-only
                status = st.text_input("Status", value="active", disabled=True)
                st.caption("New tickets are created as 'active' by default.")
                
                if st.form_submit_button("Add Ticket"):
                    if not sel_a: st.error("Please select an attraction first.")
                    else:
                        before_pop = trigger_check('attraction', 'attraction_id', sel_a, 'popularity_score')
                        new_tk_id = get_next_id('ticket', 'ticket_id')
                        # Insert loaded price and 'active'
                        if run_exec("INSERT INTO ticket (ticket_id, customer_id, attraction_id, visit_date, purchase_date, price, ticket_status) VALUES (%s, %s, %s, %s, CURRENT_DATE, %s, 'active')", [new_tk_id, curr_user, int(sel_a), v_date, def_price]):
                            st.success("Ticket added successfully.")
                            after_pop = trigger_check('attraction', 'attraction_id', sel_a, 'popularity_score')
                            if after_pop is not None and before_pop is not None and after_pop != before_pop:
                                st.info(f"Popularity score was updated automatically by trigger. (Before: {before_pop}, After: {after_pop})")
                            else:
                                st.warning("Trigger for popularity update is not installed in the current schema or did not trigger.")
                            time.sleep(2)
                            st.rerun()

    with c2:
        if sel_idx is not None:
            tk_id = int(df.iloc[sel_idx]['db_id'])
            tk_data = run_query("SELECT * FROM ticket WHERE ticket_id = %s", [tk_id])
            if tk_data:
                t = tk_data[0]
                st.write("### Edit Ticket")
                with st.form("edit_ticket_form"):
                    custs = run_query("SELECT customer_id, full_name FROM customer")
                    attrs = run_query("SELECT attraction_id, attraction_name FROM attraction")
                    c_opt = {c['customer_id']: c['full_name'] for c in custs}
                    a_opt = {a['attraction_id']: a['attraction_name'] for a in attrs}
                    
                    try: c_idx = list(c_opt.keys()).index(t['customer_id'])
                    except: c_idx = 0
                    try: a_idx = list(a_opt.keys()).index(t['attraction_id'])
                    except: a_idx = 0
                    
                    sel_c = st.selectbox("Customer", list(c_opt.keys()), format_func=lambda x: c_opt[x], index=c_idx)
                    sel_a = st.selectbox("Attraction", list(a_opt.keys()), format_func=lambda x: a_opt[x], index=a_idx)
                    v_date = st.date_input("Visit Date", value=t['visit_date'])
                    price = st.number_input("Price (₪)", min_value=0.0, value=float(t['price'] or 0.0), step=1.0)
                    
                    status_opts = ["active", "used", "cancelled"]
                    try: s_idx = status_opts.index((t.get('ticket_status') or 'active').lower())
                    except: s_idx = 0
                    status = st.selectbox("Status", status_opts, index=s_idx)
                    
                    if st.form_submit_button("Save Changes"):
                        if run_exec("UPDATE ticket SET customer_id=%s, attraction_id=%s, visit_date=%s, price=%s, ticket_status=%s WHERE ticket_id=%s", [int(sel_c), int(sel_a), v_date, price, status, tk_id]):
                            st.success("Changes saved successfully.")
                            time.sleep(1)
                            st.rerun()
                
                with st.form("del_ticket"):
                    if st.form_submit_button("🗑️ Delete Ticket", use_container_width=True):
                        if run_exec("DELETE FROM ticket WHERE ticket_id = %s", [tk_id]):
                            st.success("Record deleted successfully.")
                            time.sleep(1)
                            st.rerun()

# ---------------------------------------------------------
# 6. Customers
# ---------------------------------------------------------
elif app_mode == "👤 Customers":
    st.title("Customers Management")
    c1, c2 = st.columns([6, 4])
    
    with c1:
        st.subheader("All Customers")
        custs = run_query("""
            SELECT customer_id AS db_id, customer_id AS "#", full_name AS "Name", email AS "Email", phone AS "Phone", register_date AS "Registered"
            FROM customer ORDER BY customer_id ASC
        """)
        if custs:
            df = pd.DataFrame(custs)
            
            with st.expander("🔍 Filters", expanded=False):
                f_name = st.text_input("Name", key="cu_fname")
                f_email = st.text_input("Email", key="cu_femail")
                f_phone = st.text_input("Phone", key="cu_fphone")
                if f_name: df = df[df["Name"].astype(str).str.contains(f_name, case=False, na=False)]
                if f_email: df = df[df["Email"].astype(str).str.contains(f_email, case=False, na=False)]
                if f_phone: df = df[df["Phone"].astype(str).str.contains(f_phone, case=False, na=False)]
                
            df['#'] = range(1, len(df)+1)
            event = st.dataframe(df.drop(columns=['db_id']), selection_mode="single-row", on_select="rerun", use_container_width=True, hide_index=True)
            sel_idx = event.selection.rows[0] if event.selection.rows else None
        else:
            st.info("No customers found.")
            sel_idx = None
            
        with st.expander("➕ Add Customer"):
            with st.form("add_cust_form"):
                n = st.text_input("Full Name *")
                e = st.text_input("Email *")
                p = st.text_input("Phone")
                av = st.text_input("Avatar URL")
                reg = st.date_input("Register Date", value=date.today())
                if st.form_submit_button("Add Customer"):
                    if not n or not e: st.error("Name and Email are required.")
                    else:
                        new_id = get_next_id('customer', 'customer_id')
                        if run_exec("INSERT INTO customer (customer_id, full_name, email, phone, avatar_url, register_date) VALUES (%s, %s, %s, %s, %s, %s)", [new_id, n, e, p, av, reg]):
                            st.success("Customer added successfully.")
                            time.sleep(1)
                            st.rerun()

    with c2:
        if sel_idx is not None:
            c_id = int(df.iloc[sel_idx]['db_id'])
            c_data = run_query("SELECT * FROM customer WHERE customer_id = %s", [c_id])
            if c_data:
                c = c_data[0]
                av = c.get('avatar_url') or f"https://ui-avatars.com/api/?name={c.get('full_name','User').replace(' ','+')}&background=0F766E&color=fff"
                st.markdown(f'<div style="text-align: center;"><img src="{av}" style="width: 80px; border-radius: 50%; border: 3px solid #E2E8F0;"></div>', unsafe_allow_html=True)
                st.write("### Edit Customer")
                with st.form("edit_cust_form"):
                    n = st.text_input("Full Name", value=c['full_name'])
                    e = st.text_input("Email", value=c.get('email') or '')
                    p = st.text_input("Phone", value=c.get('phone') or '')
                    av_url = st.text_input("Avatar URL", value=c.get('avatar_url') or '')
                    if st.form_submit_button("Save Changes"):
                        if run_exec("UPDATE customer SET full_name=%s, email=%s, phone=%s, avatar_url=%s WHERE customer_id=%s", [n, e, p, av_url, c_id]):
                            st.success("Customer updated successfully.")
                            time.sleep(1)
                            st.rerun()
                            
                with st.form("activity_form"):
                    if st.form_submit_button("Check Activity Level (Stage D)", use_container_width=True):
                        chk = run_query("SELECT 1 FROM pg_proc WHERE proname = 'fn_get_customer_activity_level'")
                        if not chk:
                            st.error("Missing Function: You need to run StageD/Functions.sql on the current DB. `fn_get_customer_activity_level` does not exist.")
                        else:
                            res = run_query("SELECT fn_get_customer_activity_level(%s) as lvl", [int(c_id)])
                            if res and res[0].get('lvl') is not None:
                                st.success(f"Function executed successfully! Customer '{c['full_name']}' Activity Level: **{res[0]['lvl']}**")
                            else:
                                st.warning("Execution failed or returned None. Make sure you have loaded sufficient data.")
                            
                with st.form("del_cust"):
                    if st.form_submit_button("🗑️ Delete Customer", use_container_width=True):
                        if run_exec("DELETE FROM customer WHERE customer_id = %s", [c_id]):
                            st.success("Record deleted successfully.")
                            time.sleep(1)
                            st.rerun()

# ---------------------------------------------------------
# 7. Attractions
# ---------------------------------------------------------
elif app_mode == "🏞️ Attractions":
    st.title("Attractions Management")
    
    with st.expander("🛠️ Admin Tools: Data Quality Helpers"):
        st.write("Fills missing fields added during integration (like price, duration, avg_rating) without overwriting existing values. Useful for data stabilization.")
        with st.form("dq_form"):
            if st.form_submit_button("Fill Missing Attraction Details (Safe Auto-fill)"):
                sqls = [
                    "UPDATE attraction SET price_per_person = 15.00 WHERE price_per_person IS NULL",
                    "UPDATE attraction SET duration_hours = 2 WHERE duration_hours IS NULL",
                    "UPDATE attraction SET target_audience = 'Families' WHERE target_audience IS NULL",
                    "UPDATE attraction SET attraction_status = 'ACTIVE' WHERE attraction_status IS NULL",
                    "UPDATE attraction SET popularity_score = 0 WHERE popularity_score IS NULL",
                    "UPDATE attraction SET avg_rating = 0 WHERE avg_rating IS NULL"
                ]
                for s in sqls: run_exec(s)
                st.success("Missing details filled successfully!")
                time.sleep(1)
                st.rerun()
                
    c1, c2 = st.columns([6, 4])
    
    with c1:
        st.subheader("All Attractions")
        atts = run_query("""
            SELECT a.attraction_id AS db_id, a.attraction_id AS "#", a.attraction_name AS "Name", COALESCE(a.city, a.location, '---') AS "City", 
                   COALESCE(cat.name, a.category, '---') AS "Category",
                   COALESCE(dif.name, 'Not Set') AS "Difficulty",
                   COALESCE(a.price_per_person, 0.0) AS "Price",
                   COALESCE(a.duration_hours, 0) AS "Hours",
                   COALESCE(a.target_audience, '---') AS "Audience",
                   COALESCE(a.avg_rating, (SELECT AVG(rating) FROM review r JOIN ticket t ON r.ticket_id = t.ticket_id WHERE t.attraction_id = a.attraction_id), 0.0) AS "Rating",
                   COALESCE(a.popularity_score, 0) AS "Popularity",
                   COALESCE(a.attraction_status, '---') AS "Status"
            FROM attraction a
            LEFT JOIN category cat ON a.category_id = cat.category_id
            LEFT JOIN difficulty_level dif ON a.difficulty_id = dif.difficulty_id
            ORDER BY a.attraction_id ASC
        """)
        if atts:
            df = pd.DataFrame(atts)
            
            with st.expander("🔍 Filters", expanded=False):
                f1, f2, f3 = st.columns(3)
                f_name = f1.text_input("Name", key="at_fname")
                f_city = f2.text_input("City", key="at_fcity")
                f_cat = f3.text_input("Category", key="at_fcat")
                if f_name: df = df[df["Name"].astype(str).str.contains(f_name, case=False, na=False)]
                if f_city: df = df[df["City"].astype(str).str.contains(f_city, case=False, na=False)]
                if f_cat: df = df[df["Category"].astype(str).str.contains(f_cat, case=False, na=False)]
                
            df['#'] = range(1, len(df)+1)
            df['Rating'] = df['Rating'].astype(float).round(2)
            df['Price'] = df['Price'].astype(float).round(2)
            event = st.dataframe(df.drop(columns=['db_id']), selection_mode="single-row", on_select="rerun", use_container_width=True, hide_index=True)
            sel_idx = event.selection.rows[0] if event.selection.rows else None
        else:
            st.info("No attractions found.")
            sel_idx = None
            
        with st.expander("➕ Add Attraction"):
            with st.form("add_attr"):
                cats = run_query("SELECT category_id, name FROM category")
                cat_opts = {c['category_id']: c['name'] for c in cats}
                dif = run_query("SELECT difficulty_id, name FROM difficulty_level")
                dif_opts = {d['difficulty_id']: d['name'] for d in dif}
                
                n = st.text_input("Attraction Name *")
                c = st.text_input("City/Location")
                cat_id = st.selectbox("Category", list(cat_opts.keys()), format_func=lambda x: cat_opts[x]) if cat_opts else None
                dif_id = st.selectbox("Difficulty", list(dif_opts.keys()), format_func=lambda x: dif_opts[x]) if dif_opts else None
                p = st.number_input("Price Per Person (₪)", min_value=0.0, step=1.0)
                h = st.number_input("Duration Hours", min_value=0, step=1)
                ta = st.text_input("Target Audience")
                img = st.text_input("Main Image URL")
                
                stat = st.text_input("Status", value="ACTIVE", disabled=True)
                st.caption("New attractions are created with 'ACTIVE' status by default.")
                
                desc = st.text_area("Description")
                
                if st.form_submit_button("Add Attraction"):
                    if not n: st.error("Attraction Name is required.")
                    else:
                        new_a_id = get_next_id('attraction', 'attraction_id')
                        if run_exec("INSERT INTO attraction (attraction_id, attraction_name, city, category_id, difficulty_id, price_per_person, duration_hours, target_audience, main_image_url, attraction_status, description) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, 'ACTIVE', %s)", 
                                    [new_a_id, n, c, int(cat_id) if cat_id else None, int(dif_id) if dif_id else None, p, h, ta, img, desc]):
                            st.success("Attraction added successfully.")
                            time.sleep(1)
                            st.rerun()

    with c2:
        if sel_idx is not None:
            a_id = int(df.iloc[sel_idx]['db_id'])
            a_data = run_query("SELECT * FROM attraction WHERE attraction_id = %s", [a_id])
            if a_data:
                a = a_data[0]
                
                st.markdown("### Attraction Details")
                if a.get('main_image_url'):
                    st.image(a['main_image_url'], use_container_width=True)
                
                st.markdown(f"""
                <div style="background: white; padding: 20px; border-radius: 12px; border: 1px solid #E2E8F0; margin-bottom: 20px;">
                    <div style="font-size: 24px; font-weight: bold; color: #0F766E;">{a.get('attraction_name')}</div>
                    <div style="color: #64748B; margin-bottom: 15px;">📍 {a.get('city') or a.get('location') or 'Unknown Location'}</div>
                    <div style="display: flex; flex-wrap: wrap; gap: 10px; margin-bottom: 15px;">
                        <span style="background: #F1F5F9; padding: 5px 10px; border-radius: 5px; font-size: 14px;">₪ {a.get('price_per_person') or '0.0'}</span>
                        <span style="background: #F1F5F9; padding: 5px 10px; border-radius: 5px; font-size: 14px;">⏱️ {a.get('duration_hours') or '0'} hrs</span>
                        <span style="background: #F1F5F9; padding: 5px 10px; border-radius: 5px; font-size: 14px;">⭐ {a.get('avg_rating') or '0.0'}</span>
                        <span style="background: #F1F5F9; padding: 5px 10px; border-radius: 5px; font-size: 14px;">🔥 Pop: {a.get('popularity_score') or '0'}</span>
                        <span style="background: #F1F5F9; padding: 5px 10px; border-radius: 5px; font-size: 14px;">🏷️ {a.get('attraction_status') or 'ACTIVE'}</span>
                    </div>
                    <div style="color: #334155; font-size: 15px; line-height: 1.5;">{a.get('description') or 'No description provided.'}</div>
                </div>
                """, unsafe_allow_html=True)
                
                b1, b2 = st.columns(2)
                with b1:
                    if st.button("✏️ Edit Attraction", use_container_width=True):
                        st.session_state[f"edit_attr_{a_id}"] = not st.session_state.get(f"edit_attr_{a_id}", False)
                with b2:
                    with st.form("del_attr"):
                        if st.form_submit_button("🗑️ Delete Attraction", use_container_width=True):
                            if run_exec("DELETE FROM attraction WHERE attraction_id = %s", [a_id]):
                                st.success("Record deleted successfully.")
                                time.sleep(1)
                                st.rerun()

                if st.session_state.get(f"edit_attr_{a_id}", False):
                    st.write("---")
                    with st.form("edit_attr_form"):
                        cats = run_query("SELECT category_id, name FROM category")
                        cat_opts = {c['category_id']: c['name'] for c in cats}
                        dif = run_query("SELECT difficulty_id, name FROM difficulty_level")
                        dif_opts = {d['difficulty_id']: d['name'] for d in dif}
                        
                        n = st.text_input("Name", value=a.get('attraction_name') or '')
                        c = st.text_input("City/Location", value=a.get('city') or a.get('location') or '')
                        
                        try: c_idx = list(cat_opts.keys()).index(a.get('category_id'))
                        except: c_idx = 0
                        cat_id = st.selectbox("Category", list(cat_opts.keys()), format_func=lambda x: cat_opts[x], index=c_idx) if cat_opts else None
                        
                        try: d_idx = list(dif_opts.keys()).index(a.get('difficulty_id'))
                        except: d_idx = 0
                        dif_id = st.selectbox("Difficulty", list(dif_opts.keys()), format_func=lambda x: dif_opts[x], index=d_idx) if dif_opts else None
                        
                        p = st.number_input("Price (₪)", value=float(a.get('price_per_person') or 0.0), step=1.0)
                        h = st.number_input("Duration Hours", value=int(a.get('duration_hours') or 0), step=1)
                        ta = st.text_input("Target Audience", value=a.get('target_audience') or '')
                        ar = st.number_input("Avg Rating", value=float(a.get('avg_rating') or 0.0), format="%.2f")
                        pop = st.number_input("Popularity Score", value=int(a.get('popularity_score') or 0))
                        stat = st.text_input("Status", value=a.get('attraction_status') or '')
                        
                        u = st.text_input("Image URL", value=a.get('main_image_url') or '')
                        d = st.text_area("Description", value=a.get('description') or '')
                        
                        if st.form_submit_button("Save Changes"):
                            if run_exec("UPDATE attraction SET attraction_name=%s, city=%s, category_id=%s, difficulty_id=%s, price_per_person=%s, duration_hours=%s, target_audience=%s, avg_rating=%s, popularity_score=%s, attraction_status=%s, main_image_url=%s, description=%s WHERE attraction_id=%s", [n, c, int(cat_id) if cat_id else None, int(dif_id) if dif_id else None, p, h, ta, ar, pop, stat, u, d, a_id]):
                                st.success("Changes saved successfully.")
                                st.session_state[f"edit_attr_{a_id}"] = False
                                time.sleep(1)
                                st.rerun()

# ---------------------------------------------------------
# 8. Table Manager (CRUD)
# ---------------------------------------------------------
elif app_mode == "🗄️ Table Manager":
    st.title("Table Manager (Admin)")
    tables = db.get_tables()
    sel_table = st.selectbox("Select Table", tables)
    
    if sel_table:
        st.write(f"### Data in `{sel_table}`")
        data = run_query(f'SELECT * FROM "{sel_table}" ORDER BY 1 ASC LIMIT 100')
        
        if data:
            df = pd.DataFrame(data)
            
            with st.expander("🔍 Filter Data"):
                col = st.selectbox("Column to filter", df.columns)
                val = st.text_input("Contains")
                if val:
                    df = df[df[col].astype(str).str.contains(val, case=False, na=False)]
                    
            df.insert(0, 'Row', range(1, 1 + len(df)))
            event = st.dataframe(df, selection_mode="single-row", on_select="rerun", use_container_width=True, hide_index=True)
            sel_idx = event.selection.rows[0] if event.selection.rows else None
        else:
            st.info("Table is empty.")
            df = pd.DataFrame(columns=[c['column_name'] for c in db.get_columns(sel_table)])
            sel_idx = None
            
        pks = db.get_primary_key(sel_table)
        pk = pks[0] if pks else None
        
        c1, c2 = st.columns(2)
        
        # Helper to generate correct input type in table manager
        def dynamic_input(cname, dtype, val=None):
            if cname == 'ticket_status':
                opts = ["active", "used", "cancelled"]
                try: idx = opts.index((val or 'active').lower())
                except: idx = 0
                return st.selectbox(cname, opts, index=idx)
            if cname == 'is_deleted':
                opts = [False, True]
                try: idx = opts.index(val if val is not None else False)
                except: idx = 0
                return st.selectbox(cname, opts, index=idx)
            if cname == 'rating':
                return st.number_input(cname, min_value=1, max_value=5, value=int(val or 5))
            if cname == 'category_id':
                cats = run_query("SELECT category_id, name FROM category")
                opts = {c['category_id']: f"{c['name']} (ID: {c['category_id']})" for c in cats}
                if not opts: return st.text_input(cname, value=str(val or ''))
                try: idx = list(opts.keys()).index(val)
                except: idx = 0
                return st.selectbox(cname, list(opts.keys()), format_func=lambda x: opts[x], index=idx)
            if cname == 'difficulty_id':
                difs = run_query("SELECT difficulty_id, name FROM difficulty_level")
                opts = {d['difficulty_id']: f"{d['name']} (ID: {d['difficulty_id']})" for d in difs}
                if not opts: return st.text_input(cname, value=str(val or ''))
                try: idx = list(opts.keys()).index(val)
                except: idx = 0
                return st.selectbox(cname, list(opts.keys()), format_func=lambda x: opts[x], index=idx)
            return st.text_input(cname, value=str(val or ''))
            
        with c1:
            with st.expander("➕ Add New Row"):
                with st.form("tm_add"):
                    cols = db.get_columns(sel_table)
                    inputs = {}
                    for col in cols:
                        cname = col['column_name']
                        dtype = col.get('data_type')
                        if cname == pk and dtype == 'integer': continue
                        inputs[cname] = dynamic_input(cname, dtype)
                    if st.form_submit_button("Insert"):
                        keys = list(inputs.keys())
                        vals = list(inputs.values())
                        ph = ", ".join(["%s"] * len(keys))
                        kstr = ", ".join([f'"{k}"' for k in keys])
                        sql = f'INSERT INTO "{sel_table}" ({kstr}) VALUES ({ph})'
                        if run_exec(sql, vals):
                            st.success("Row inserted successfully.")
                            time.sleep(1)
                            st.rerun()
                            
        with c2:
            if sel_idx is not None and pk:
                row_data = data[sel_idx]
                with st.expander("✏️ Edit Selected Row", expanded=True):
                    with st.form("tm_edit"):
                        cols = db.get_columns(sel_table)
                        upd_inputs = {}
                        for col in cols:
                            cname = col['column_name']
                            upd_inputs[cname] = dynamic_input(cname, col.get('data_type'), row_data.get(cname))
                        if st.form_submit_button("Update"):
                            keys = [k for k in upd_inputs.keys() if k != pk]
                            vals = [upd_inputs[k] for k in keys]
                            set_str = ", ".join([f'"{k}" = %s' for k in keys])
                            sql = f'UPDATE "{sel_table}" SET {set_str} WHERE "{pk}" = %s'
                            vals.append(row_data[pk])
                            if run_exec(sql, vals):
                                st.success("Changes saved successfully.")
                                time.sleep(1)
                                st.rerun()
                with st.form("tm_del"):
                    if st.form_submit_button("🗑️ Delete Selected Row", use_container_width=True):
                        if run_exec(f'DELETE FROM "{sel_table}" WHERE "{pk}" = %s', [int(row_data[pk])]):
                            st.success("Record deleted successfully.")
                            time.sleep(1)
                            st.rerun()
            elif not pk:
                st.warning("This table has no primary key, edit/delete disabled.")
            else:
                st.info("Select a row from the table to edit or delete.")

# ---------------------------------------------------------
# 9. Database Programs
# ---------------------------------------------------------
elif app_mode == "⚙️ Database Programs":
    st.title("Database Programs (Stage D)")
    st.write("Execute the real stored procedures and functions.")
    
    c1, c2 = st.columns(2)
    with c1:
        st.subheader("Calculate Attraction Quality")
        with st.form("prog_1"):
            attrs = run_query("SELECT attraction_id, attraction_name FROM attraction")
            a_opt = {a['attraction_id']: a['attraction_name'] for a in attrs}
            sel_a = st.selectbox("Attraction", list(a_opt.keys()), format_func=lambda x: a_opt[x]) if a_opt else None
            if st.form_submit_button("Run Function"):
                if sel_a:
                    st.info("Running...")
                    res = run_query("SELECT fn_calculate_attraction_quality(%s) as q", [int(sel_a)])
                    if res and res[0].get('q') is not None: 
                        st.success(f"Function fn_calculate_attraction_quality executed successfully.")
                        st.success(f"Attraction: '{a_opt[sel_a]}' - Quality Score: **{res[0]['q']}**")
                    else: 
                        st.warning("This Stage D routine is not installed in the current database schema: fn_calculate_attraction_quality.")
                
        st.subheader("Mark Problematic Attractions")
        st.info("This procedure updates attraction_status according to ratings, reviews, reports, cancellations and popularity_score.")
        with st.form("prog_4"):
            if st.form_submit_button("Run Procedure"):
                st.info("Running...")
                before = run_query("SELECT attraction_id, attraction_status FROM attraction")
                chk = run_query("SELECT 1 FROM pg_proc WHERE proname = 'pr_mark_problematic_attractions'")
                if not chk:
                    st.error("Missing Procedure: You need to run StageD/Procedures.sql on the current DB. `pr_mark_problematic_attractions` does not exist.")
                else:
                    if run_exec("CALL pr_mark_problematic_attractions()"):
                        st.success("Procedure pr_mark_problematic_attractions executed successfully.")
                        after = run_query("SELECT attraction_id, attraction_name, attraction_status FROM attraction")
                        b_map = {x['attraction_id']: x['attraction_status'] for x in before} if before else {}
                        changed = [x for x in after if b_map.get(x['attraction_id']) != x['attraction_status']]
                        if changed:
                            st.write("Status changes:")
                            st.dataframe(pd.DataFrame(changed))
                        else:
                            st.info("No attraction statuses were changed.")
                    else:
                        st.warning("Execution failed.")

    with c2:
        st.subheader("Check Customer Activity")
        with st.form("prog_3"):
            custs = run_query("SELECT customer_id, full_name FROM customer")
            c_opt = {c['customer_id']: c['full_name'] for c in custs}
            sel_c = st.selectbox("Customer", list(c_opt.keys()), format_func=lambda x: c_opt[x]) if c_opt else None
            if st.form_submit_button("Run Function"):
                if sel_c:
                    st.info("Running...")
                    chk = run_query("SELECT 1 FROM pg_proc WHERE proname = 'fn_get_customer_activity_level'")
                    if not chk:
                        st.error("Missing Function: You need to run StageD/Functions.sql on the current DB. `fn_get_customer_activity_level` does not exist.")
                    else:
                        res = run_query("SELECT fn_get_customer_activity_level(%s) as lvl", [int(sel_c)])
                        if res and res[0].get('lvl') is not None:
                            st.success(f"Function executed successfully! Customer '{c_opt[sel_c]}' Activity Level: **{res[0]['lvl']}**")
                        else:
                            st.warning("Execution failed or returned None. Make sure the customer has bookings.")
                            
        st.subheader("Refresh Attraction Popularity")
        with st.form("prog_2"):
            if st.form_submit_button("Run Procedure"):
                st.info("Running...")
                chk = run_query("SELECT 1 FROM pg_proc WHERE proname = 'pr_refresh_attraction_popularity'")
                if not chk:
                    st.error("Missing Procedure: You need to run StageD/Procedures.sql on the current DB. `pr_refresh_attraction_popularity` does not exist.")
                else:
                    if run_exec("CALL pr_refresh_attraction_popularity()"):
                        st.success("Procedure pr_refresh_attraction_popularity executed successfully.")
                    else:
                        st.warning("Execution failed.")
