-- Which users may see which Specter cameras. Cameras themselves live in Specter, so the camera is
-- referenced by its Specter id (camera_<32 hex>) and has no foreign key here.
create table public.camera_assignments (
  id UUID default gen_random_uuid () primary key,
  specter_camera_id TEXT not null check (specter_camera_id ~ '^camera_[0-9a-f]{32}$'),
  user_id UUID not null references public.users(id) on delete cascade,
  assigned_by UUID references public.users(id) on delete set null,
  assigned_at timestamp with time zone default NOW(),
  unique(specter_camera_id, user_id)
);

create index idx_camera_assignments_user on public.camera_assignments (user_id);

-- The old public.cameras and public.camera_user_assignments tables are no longer read. Drop them
-- only after confirming nothing else uses them.
