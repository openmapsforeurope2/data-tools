CREATE SCHEMA prod;
CREATE SCHEMA work;
CREATE SCHEMA ref;
CREATE SCHEMA release;

-- Pas de gestion de droits sur la GPF (pour une base classique, il faudra lancer les instructions suivantes)
GRANT ALL ON SCHEMA prod TO g_ome2_user;
GRANT ALL ON SCHEMA work TO g_ome2_user;
GRANT ALL ON SCHEMA ref TO g_ome2_user;
GRANT ALL ON SCHEMA release TO g_ome2_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON tables TO g_ome2_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA prod GRANT ALL ON tables TO g_ome2_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA work GRANT ALL ON tables TO g_ome2_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA ref GRANT ALL ON tables TO g_ome2_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA release GRANT ALL ON tables TO g_ome2_user;

GRANT ALL ON ALL TABLES IN SCHEMA public TO g_ome2_user;
GRANT ALL ON ALL TABLES IN SCHEMA prod TO g_ome2_user;
GRANT ALL ON ALL TABLES IN SCHEMA work TO g_ome2_user;
GRANT ALL ON ALL TABLES IN SCHEMA ref TO g_ome2_user;
GRANT ALL ON ALL TABLES IN SCHEMA release TO g_ome2_user;