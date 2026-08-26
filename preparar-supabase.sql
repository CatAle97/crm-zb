-- CRM Zona Bariátrica — preparar la base de datos
-- Se puede correr varias veces sin romper nada.

-- 1) La tabla donde vive todo el CRM
create table if not exists public.crm_estado (
  id              int primary key,
  data            jsonb not null default '{}'::jsonb,
  actualizado_en  timestamptz default now(),
  actualizado_por text
);

-- 2) La fila única (el CRM siempre lee/escribe id = 1)
insert into public.crm_estado (id, data)
values (1, '{}'::jsonb)
on conflict (id) do nothing;

-- 3) Candado: solo quien inició sesión puede ver o cambiar los datos.
--    Sin esto, cualquiera con el enlace podría leer la cartera de clientes.
alter table public.crm_estado enable row level security;

drop policy if exists "crm_lectura_autenticados"  on public.crm_estado;
create policy "crm_lectura_autenticados" on public.crm_estado
  for select to authenticated using (true);

drop policy if exists "crm_escritura_autenticados" on public.crm_estado;
create policy "crm_escritura_autenticados" on public.crm_estado
  for update to authenticated using (true) with check (true);

-- 4) Tiempo real: que Roberto y Genesis vean los cambios del otro al instante
do $$
begin
  alter publication supabase_realtime add table public.crm_estado;
exception
  when duplicate_object then null;
end $$;
