## Email Confirmation Flow Setup

This guide explains how to brand the Supabase confirmation email and send users to the custom confirmation landing page that lives in this repository.

### 1. Prepare Brand Assets

1. In the Supabase dashboard, open **Storage → Buckets** and create a new public bucket (for example, `branding`).
2. Upload the logo assets from `Assets/` (at minimum `Logo_with_text.png`).  
   - Right-click each uploaded file → **Copy public URL**.  
   - You will paste these URLs into both the email template and landing page files.

> Tip: If you already distribute static assets from another CDN or domain, you can use that URL instead. The important part is that the image source is public and served over HTTPS.

### 2. Add the Custom Email Template

1. Open `supabase/email_templates/confirm_signup.html` in your editor.
2. Replace the placeholder URL `https://YOUR_STORAGE_BUCKET_URL/Logo_with_text.png` with the public URL copied in the previous step.
3. In the Supabase dashboard go to **Authentication → Email Templates → Confirm signup**.
4. Enable **Use custom template**, paste the contents of `confirm_signup.html`, and click **Save changes**.
5. (Optional) Fill in the text-version tab with a short plaintext fallback such as:
   ```
   Cookpad email confirmation
   Click the link to confirm your account: {{ .ConfirmationURL }}
   ```

Supabase automatically injects values like `{{ .ConfirmationURL }}` and `{{ .Email }}` at send time. Do not edit those placeholders.

### 3. Publish the Confirmation Landing Page

The styled confirmation page is located at `web/email-confirmed.html`. It is a standalone HTML file that works with any static host (Supabase Edge Functions, Netlify, Vercel, S3/CloudFront, GitHub Pages, etc.).

1. Update the `<img src="...">` in `web/email-confirmed.html` with the same public logo URL you used in the email template.
2. (Optional) Update the CTA link (`href="cookpad://home"`) if you have a different deep link or want to point to a support page.
3. Deploy the page:
   - **Single page deploy:** Drag `web/email-confirmed.html` into your static host of choice. Most providers let you host a single file by dropping it into their dashboard.
   - **Flutter web build:** If you already deploy the entire Flutter web app, ensure this file is copied over. For example:
     ```bash
     flutter build web
     ```
     Then copy `build/web/email-confirmed.html` (and any supporting assets) to your hosting bucket.
4. Note the final public URL of the page (e.g., `https://cookpad.example.com/email-confirmed`).

### 4. Point Supabase to the Landing Page

1. In the Supabase dashboard navigate to **Authentication → URL Configuration**.
2. Set **Site URL** to the domain where you are hosting the confirmation page (e.g., `https://cookpad.example.com`).
3. Add the exact confirmation page path to **Additional redirect URLs** (e.g., `https://cookpad.example.com/email-confirmed`).
4. Click **Save**.

From now on, Supabase will append `?redirect_to=` parameters to `{{ .ConfirmationURL }}` so that after the user clicks the email button and the token is verified, they are redirected to your custom page.

### 5. Test the Flow End to End

1. In a development build run the sign-up flow with a fresh email:
   ```dart
   await Supabase.instance.client.auth.signUp(
     email: email,
     password: password,
     // Optional: override redirect at runtime
     emailRedirectTo: 'https://cookpad.example.com/email-confirmed',
   );
   ```
2. Confirm that the received email matches the new template and that the button link opens your confirmation page after verification.
3. Verify that deep links or CTA buttons on the landing page behave as expected on both mobile and desktop.

### 6. Keep Production Keys Safe

- Do not commit your production Supabase anon key or service role keys. Use environment variables (`.env`) and the existing `env_template.txt` to document required values.
- If you make additional changes to email templates, store the HTML in version control (as done above) so you always have a trusted copy.

With these steps in place, users who sign up will receive a branded confirmation email and land on the Cookpad-styled confirmation page once their email is verified.


