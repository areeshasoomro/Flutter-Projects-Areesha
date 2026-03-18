# 🛡️ DataVault — Secure File Sharing & Access Analytics Application 


DataVault is a professional-grade cybersecurity asset management platform designed to solve the critical problem of "static link leakage." Unlike traditional cloud sharing where links remain active forever with zero oversight(No tracking ), DataVault provides a **Zero-Trust** ecosystem for sharing sensitive information with real-time monitoring and active revocation.

---

## 🎯 Problem Understanding
In modern digital workflows, sensitive documents (PDFs, credentials, reports) are often shared via direct cloud links (Google Drive, Dropbox). This approach has three fatal flaws:
1. **Zero Control After Sharing**: Once a link is sent, it cannot be easily "un-sent" or modified.
2. **Permanent Exposure**: Links stay active indefinitely, increasing the attack surface.
3. **No Audit Trail**: Owners have no idea if their file was viewed once, ten times, or by unauthorized parties.

---
Solution
## 🚀 The DataVault Approach (Our Differentiator)
We didn't just build a file uploader; we built a **Secure Delivery Pipeline**.

### 1. The Gatekeeper Architecture
We implemented a decoupled system:
*   **Android Management App**: A high-security vault for owners to upload, set rules, and monitor live traffic.
*   **Web Secure Portal**: A dedicated "Clean Room" where guests must pass security checks (passwords, expiry, limits) before the source file is ever exposed , we implemented 3 tier validation.

### 2. Multi-Layer Validation
Every access attempt goes through a real-time validation sequence:
*   **Temporal Expiry**: Links expire at an exact minute set by the owner.
*   **Download Throttling**: Hard limits on the number of successful views (e.g., "Burn after 1 view").
*   **Identity Verification**: Optional but enforced password protection.

### 3. Active Revocation & Analytics
Owners can see a **Live Feed** of access attempts. If suspicious activity is detected (e.g., repeated wrong passwords), the owner can click **"Revoke Access"** to instantly kill the link globally.

---

## ✨ Key Features
*   ✅ **Secure File Hosting**: Real file uploads integrated with Cloudinary (bypassing Firebase Storage billing restrictions).
*   ✅ **Dynamic Portal Links**: Smart URLs (`?id=token`) that mask the real source file.
*   ✅ **Real-time Analytics**: Donut-chart visualization of successful vs. blocked attempts.
*   ✅ **Live Expiry Countdown**: Ticking security timer on the analytics dashboard.
*   ✅ **Password Protection**: Encryption-style password layer for sensitive assets.
*   ✅ **One-Tap Management**: Quick actions to Share, Manage, or Permanently Delete vault items.

---

## 🛠️ Tech Stack
*   **Frontend**: Flutter (Mobile & Web)
*   **Backend**: Firebase (Authentication & Cloud Firestore)
*   **Storage**: Cloudinary API (Unsigned REST implementation)
*   **Analytics**: FL Chart
*   **Communications**: Share Plus (Native Android Integration)

---

## 🏗️ Challenges Faced & Solutions
*   **The Billing Hurdle**: Firebase Storage now requires a Credit Card for raw file uploads. 
    *   *Solution*: We pivoted to a **Cloudinary REST API** integration, allowing for real-world file hosting on the free tier without compromising security.
*   **The Direct Link Leak**: Direct storage links can be easily scraped.
    *   *Solution*: We implemented the **Portal Pattern**. The guest only sees the file *after* our backend increments the view counter and validates the session.

---

## Summary
DataVault represents a complete **Cybersecurity Product**. By combining a minimalist "Fintech" UI with robust backend logic and data visualization, we've demonstrated how modern cloud tools can be orchestrated to solve real-world privacy concerns.

**"It's not just about sharing a file; it's about owning the lifecycle of your data."**
