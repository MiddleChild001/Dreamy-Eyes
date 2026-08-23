-- Run this once in the Supabase SQL Editor after the original schema.sql.
-- It creates the secure, public media bucket used by the CMS uploader.
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles where id = auth.uid() and is_admin = true
  );
$$;

grant execute on function public.is_admin() to authenticated;

alter table public.site_settings
  add column if not exists location text not null default 'Lagos, Nigeria';

alter table public.site_settings
  add column if not exists refill_two_week text not null default '25000',
  add column if not exists refill_three_week text not null default '35000';

update public.site_settings
set location = 'Lagos, Nigeria'
where location is null or btrim(location) = '';

-- Keep historical appointment records when an admin deletes a service or slot.
alter table public.reservations
  drop constraint if exists reservations_service_id_fkey,
  add constraint reservations_service_id_fkey
    foreign key (service_id) references public.services(id) on delete set null,
  drop constraint if exists reservations_slot_id_fkey,
  add constraint reservations_slot_id_fkey
    foreign key (slot_id) references public.appointment_slots(id) on delete set null;

-- Import the content that originally lived in index.html. The WHERE clauses
-- make this safe to run more than once and keep later CMS edits intact.
insert into public.services (title, description, price, sort_order, is_published)
select seed.title, seed.description, seed.price, seed.sort_order, true
from (values
  ('Classic Dream Set', 'Clean, natural mascara finish with 1:1 isolation.', '₦35,000', 10),
  ('Lash Lift & Tint', 'Natural curl elevation with a rich black tint.', '₦30,000', 20),
  ('Hybrid Glam Set', 'Classic singles and handmade fans for soft texture.', '₦45,000', 30),
  ('Wispy Dreamy Hybrid', 'Textured spikes and soft fan layers.', '₦50,000', 40),
  ('Russian Volume Set', 'Handcrafted 3D-5D fans with a light finish.', '₦60,000', 50),
  ('Mega Dream Volume', 'Maximum fullness using ultra-fine fan fibres.', '₦75,000', 60)
) as seed(title, description, price, sort_order)
where not exists (select 1 from public.services where services.title = seed.title);

insert into public.gallery_items (title, description, image_url, alt_text, sort_order, is_published)
select seed.title, seed.description, seed.image_url, seed.alt_text, seed.sort_order, true
from (values
  ('Soft volume', 'Weightless fullness with a feathered finish.', 'https://product.hstatic.net/200000931523/product/3_6d2883b149374419b17e2d4d5a70c663_grande.png', 'Close-up of a soft volume lash extension set', 10),
  ('Wispy hybrid', 'Texture, lift and intentional detail.', 'https://images.squarespace-cdn.com/content/v1/64b35e354656c26fd849ed8e/1706513108844-8NUZJ99MMGFWKX03V3Q5/Feed%2B-%2BEva%2BSpikey.png', 'Close-up of a wispy lash extension set', 20),
  ('Russian volume', 'Full, precise fans with a soft lash line.', 'https://static.wixstatic.com/media/34d4c4_0315708a0dd7406aa624a5c42c0e0129~mv2.jpg/v1/fill/w_1784%2Ch_1413%2Cal_c%2Cq_90%2Cenc_avif%2Cquality_auto/34d4c4_0315708a0dd7406aa624a5c42c0e0129~mv2.jpg', 'Close-up of a volume lash extension set', 30)
) as seed(title, description, image_url, alt_text, sort_order)
where not exists (select 1 from public.gallery_items where gallery_items.title = seed.title);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'lash-media',
  'lash-media',
  true,
  20971520,
  array['image/jpeg', 'image/png', 'image/webp', 'video/mp4', 'video/webm', 'video/quicktime']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

do $$
begin
  if not exists (select 1 from pg_policies where schemaname = 'storage' and tablename = 'objects' and policyname = 'CMS admins can upload lash media') then
    create policy "CMS admins can upload lash media"
      on storage.objects for insert to authenticated
      with check (bucket_id = 'lash-media' and public.is_admin());
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'storage' and tablename = 'objects' and policyname = 'CMS admins can replace lash media') then
    create policy "CMS admins can replace lash media"
      on storage.objects for update to authenticated
      using (bucket_id = 'lash-media' and public.is_admin())
      with check (bucket_id = 'lash-media' and public.is_admin());
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'storage' and tablename = 'objects' and policyname = 'CMS admins can delete lash media') then
    create policy "CMS admins can delete lash media"
      on storage.objects for delete to authenticated
      using (bucket_id = 'lash-media' and public.is_admin());
  end if;
end $$;
