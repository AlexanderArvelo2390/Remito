# Remito

## Configurar Supabase

La aplicación comparte los remitos y el catálogo mediante Supabase. Crea automáticamente una sesión anónima persistente en cada navegador; no se pide correo ni contraseña.

1. En el proyecto de Supabase, habilitá **Anonymous Sign-Ins** en **Authentication → Sign In / Providers**.
2. Abrí **SQL Editor** y ejecutá [`supabase/setup.sql`](./supabase/setup.sql).
3. En **Authentication → URL Configuration**, agregá la URL publicada de GitHub Pages a **Redirect URLs**. Para este repositorio suele ser `https://alexanderarvelo2390.github.io/Remito/`.
4. Publicá los cambios de este repositorio en GitHub Pages.

La URL del proyecto y la clave `sb_publishable` usadas por la página son credenciales públicas. **Con el acceso anónimo, cualquiera que tenga el enlace puede ver, crear, editar y borrar remitos y modificar el catálogo.** No guardes información sensible. Las políticas de Row Level Security solo aseguran que las operaciones pasen por una sesión anónima; no identifican al personal.

La sesión se conserva en cada navegador para no tener que iniciar sesión cada vez. Los remitos se eliminan mediante una tarea programada una vez por hora, cuando ya cumplieron siete días desde su último guardado. El catálogo compartido no vence.
