-- Run after schema.sql. Requires: create extension if not exists vector;

CREATE OR REPLACE FUNCTION public.match_products(query_embedding vector, match_count integer DEFAULT 5)
 RETURNS TABLE(id uuid, sku text, name text, description text, category text, price numeric,
               currency text, in_stock boolean, stock_quantity integer, specs jsonb, similarity double precision)
 LANGUAGE sql STABLE
AS $function$
  select p.id, p.sku, p.name, p.description, p.category,
         p.price, p.currency, p.in_stock, p.stock_quantity, p.specs,
         1 - (p.embedding <=> query_embedding) as similarity
  from products p
  where p.embedding is not null
  order by p.embedding <=> query_embedding
  limit match_count;
$function$;

CREATE OR REPLACE FUNCTION public.match_customer_memory(query_embedding vector, p_customer_id uuid, match_count integer DEFAULT 5)
 RETURNS TABLE(id uuid, memory_type text, content text, created_at timestamp with time zone, similarity double precision)
 LANGUAGE sql STABLE
AS $function$
  select m.id, m.memory_type, m.content, m.created_at,
         1 - (m.embedding <=> query_embedding) as similarity
  from customer_memory m
  where m.customer_id = p_customer_id
  order by m.embedding <=> query_embedding
  limit match_count;
$function$;
