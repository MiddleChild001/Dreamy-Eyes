# Dreamy Eyes CMS

This project is now a live-content site and protected CMS. The public site reads published services, gallery work, social links and appointment slots from Supabase. The admin dashboard is available at `/admin` when the Node server is running.

## Connect it

1. Create a Supabase project, then run [`supabase/schema.sql`](supabase/schema.sql) in its SQL Editor.
2. Create an email and password user in Supabase Auth. Add their user UUID to the final `update profiles` query in the schema comments so they are an admin.
3. Create a Resend account, verify the domain used in `RESEND_FROM`, and create an API key. Resend requires a verified sender domain for production delivery.
4. Copy `.env.example` to `.env` and add the real values. Do not commit `.env`.
5. Run `npm run dev`, open `http://localhost:3000`, and sign in at `http://localhost:3000/admin`.
6. Deploy the same project to a Node host such as Render, Railway, or Fly.io. Add all `.env` values as host secrets. The site must be served by this Node app, not opened as a `file://` page, for reservations and CMS content to work.

## Admin controls

The dashboard contains fields for the reservation inbox email, social links, lash menu title, price, description and published state, gallery title, description, image or video URL and alt text, and appointment slots. Saving a published item updates the live website immediately on its next load.

## Media uploads

The gallery currently accepts a direct image or video URL so content is easy to manage without exposing storage credentials. For fully managed uploads, create a public Supabase Storage bucket named `lash-media` and point each gallery item at the public URL after uploading it in Supabase Storage. This preserves storage controls and keeps service-role keys on the server only.
