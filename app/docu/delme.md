Tala de Contenidos

Overview

Flujo Visual

Proceso Detallado

GitHub Actions

Reglas Importantes

Troubleshooting

FAQ

Checklist para Nuevos Devs

Overview

¿Por Qué Este Workflow?

En equipos grandes trabajando en el mismo repositorio, el flujo tradicional (dev → stg → main) puede generar bloqueos:

Problema tradicional:

dev contiene:
- Feature A (lista, testeada) ✓
- Feature B (con bugs críticos) ✗

Resultado: Feature B bloquea el deploy de Feature A
No puedes hacer dev → stg → main


Solución:

Cada feature avanza independientemente mediante 3 PRs separados:

Feature A: main → feature-A → dev → stg → main (avanza completa)
Feature B: main → feature-B → dev (se queda aquí hasta que esté OK)
Feature C: main → feature-C → dev → stg (esperando QA)


Ventajas

✅ Sin bloqueos entre features - Cada una avanza a su ritmo ✅ Deploy selectivo - Solo lo que está listo llega a producción ✅ Flexibilidad para equipos - QA puede aprobar features independientemente ✅ Mejor control - Claridad sobre qué está en cada ambiente

Trade-offs

⚠️ Más PRs por feature - 3 en vez de 1 ⚠️ Sincronización manual - Requiere disciplina ⚠️ Más complejo - Curva de aprendizaje

Flujo Visual



Descripción del Flujo

Crear Feature - Desde main (siempre)

3 PRs Automáticos - Se crean al hacer push

Merge Secuencial - Cada PR cuando cumple requisitos

MAIN (producción)
  ↓ crear feature
FEATURE/* (desarrollo)
  ↓ PR #1
DEV (testing) → cuando CI pasa
  ↓ PR #2
STG (QA) → cuando QA aprueba
  ↓ PR #3
MAIN (producción) → cuando tech leads aprueban


Proceso Detallado

Paso 1: Crear Feature Branch

# Siempre desde main
git checkout main
git pull origin main
git checkout -b feature/backend-auth-login-API-123
git push -u origin feature/backend-auth-login-API-123


✅ Automáticamente se crean 3 PRs:

[DEV] backend-auth-login-API-123 → feature → dev

[STG] backend-auth-login-API-123 → feature → stg (draft)

[PROD] backend-auth-login-API-123 → feature → main (draft)

Paso 2: Desarrollo

# Trabajo diario
git add .
git commit -m "feat(auth): add JWT validation"
git push origin feature/backend-auth-login-API-123

# Sincronizar con main (diariamente)
git fetch origin
git rebase origin/main
git push --force-with-lease origin feature/backend-auth-login-API-123


⚠️ Importante: Sincroniza con main diariamente para evitar conflictos masivos.

Paso 3: PR #1 - Development

Cuándo: Cuando la feature funciona localmente

Requisitos:

✅ CI/CD pasa (lint + typecheck + build)

✅ Tests automáticos OK

⚠️ Code review opcional

Acción:

El PR se actualiza automáticamente con cada push

Verificar que CI pase

Mergear (sin esperar approval)

Método: MERGE commit

Paso 4: PR #2 - Staging

Cuándo: Después de mergear a dev

Requisitos:

✅ PR a dev mergeado

✅ Testing en dev OK

✅ 1 approval requerida

✅ QA sign-off

Acción:

Cambiar PR de draft a ready for review

QA testea en ambiente stg

Si falla: fix en feature branch, push (PR se actualiza)

Si pasa: QA aprueba y mergeas

Método: MERGE commit

Paso 5: PR #3 - Production

Cuándo: Después de mergear a stg

Requisitos:

✅ PR a stg mergeado

✅ QA aprobado en stg

✅ 2+ approvals (tech leads)

✅ Todos los tests pasando

Acción:

Cambiar PR de draft a ready for review

Solicitar approvals de tech leads

Verificar que todo está OK

Mergear → deploy automático a producción

Método: MERGE commit

Paso 6: Cleanup

# Automático: el branch se elimina después del merge a main
# Verificar que fue eliminado:
git fetch --prune
git branch -a | grep feature/backend-auth-login


GitHub Actions

Tenemos 2 workflows automatizados que facilitan el proceso:

1. Auto-crear PRs

Cuando haces push de un branch que sigue nuestra convención, automáticamente se ejecuta:

Workflow: .github/workflows/auto-create-prs.yml

Qué hace:

Detecta branches con los siguientes prefijos:

feature/ - Nuevas funcionalidades

fix/ - Corrección de bugs

hotfix/ - Fixes críticos urgentes

refactor/ - Refactorización de código

docs/ - Cambios en documentación

Crea/verifica labels automáticos (feature, fix, hotfix, etc.)

Crea 3 PRs automáticamente:

[DEV] nombre-del-branch → branch → dev (ready for review)

[STG] nombre-del-branch → branch → stg (draft)

[PROD] nombre-del-branch → branch → main (draft)

Convención de Nomenclatura (Importante para Trazabilidad):

# Formato recomendado:
<tipo>/<JIRA-TICKET>-descripcion-corta

# Ejemplos correctos:
feature/ACA-123-login-authentication
fix/ACA-456-header-responsive
hotfix/ACA-789-payment-critical-bug
refactor/ACA-234-auth-service
docs/ACA-567-api-documentation

# ❌ Ejemplos incorrectos (sin ticket):
feature/login
fix/bug-header

¿Por qué incluir el ticket de JIRA?

✅ Trazabilidad automática entre código y tareas

✅ Fácil identificar qué PRs pertenecen a qué historia

✅ Reporting y métricas más precisas

✅ Code review más contextual

Configuración del Workflow:

Para que funcione con todos los prefijos, el workflow debe tener:

on:
  create:
  push:
    branches:
      - 'feature/**'
      - 'fix/**'
      - 'hotfix/**'
      - 'refactor/**'
      - 'docs/**'

jobs:
  create-prs:
    runs-on: ubuntu-latest
    if: |
      startsWith(github.ref, 'refs/heads/feature/') ||
      startsWith(github.ref, 'refs/heads/fix/') ||
      startsWith(github.ref, 'refs/heads/hotfix/') ||
      startsWith(github.ref, 'refs/heads/refactor/') ||
      startsWith(github.ref, 'refs/heads/docs/')

Ventajas:

✅ Cero trabajo manual

✅ Nomenclatura consistente

✅ Checklists incluidos en cada PR

✅ Labels automáticos según tipo

✅ Trazabilidad con JIRA

No hace nada si:

Los PRs ya existen

El branch no sigue la convención de prefijos

Configuración necesaria en GitHub:

Settings → Actions → General → Workflow permissions
☑ Read and write permissions
☑ Allow GitHub Actions to create and approve pull requests

2. CI/CD - Validación Automática

Cuando abres o actualizas un PR a dev, stg o main, automáticamente se ejecuta:

Workflow: .github/workflows/ci.yml

Ejecuta build del proyecto.

Si algo falla:

❌ PR queda bloqueado

⚠️ No se puede mergear hasta corregir

🔴 Status check muestra error en rojo

Si todo pasa:

✅ PR puede mergearse

🟢 Status check muestra success en verde

Branch Protection:

Para que el CI realmente bloquee PRs, debe estar configurado:

Settings → Branches → Edit rule (dev/stg/main)

☑ Require status checks to pass before merging
  ☑ ci (este es el nombre del workflow)

Ver logs:

Actions → CI → Último run → Expandir steps

Tiempo aproximado:

Primera vez: ~2-3 minutos

Con cache: ~30-60 segundos

Reglas Importantes

✅ QUÉ HACER

Crear features desde main

git checkout main  # ✅
git checkout -b feature/nombre


Sincronizar con main diariamente

git fetch origin
git rebase origin/main
git push --force-with-lease


Usar MERGE en todos los PRs

Preserva historial

Git sabe que es el mismo código

Resolver conflictos en tu branch

# Durante rebase
git status
# Editar archivos
git add .
git rebase --continue


Mantener PRs actualizados

Push frecuente

CI corre en cada push

❌ QUÉ NO HACER

NO crear features desde dev o stg

git checkout dev   # ❌ NUNCA
git checkout -b feature/nombre


Por qué: Feature estará basada en código que puede no llegar a main

NO usar SQUASH en los PRs

# GitHub PR: "Squash and merge"  ❌ NUNCA


Por qué: Crea commits diferentes en cada branch, rompe la sincronización

NO mergear manualmente entre dev/stg/main

git checkout dev
git merge stg  # ❌ NUNCA


Por qué: Rompe el flujo de PRs independientes

NO hacer force push sin --force-with-lease

git push -f origin feature/nombre  # ❌ PELIGROSO
git push --force-with-lease        # ✅ SEGURO


Por qué: --force-with-lease verifica que no sobrescribas trabajo de otros

NO commitear directamente a main/stg/dev

git checkout main
git commit -m "fix"  # ❌ PROHIBIDO


Por qué: Estas branches están protegidas, siempre vía PR

NO dejar features sin sincronizar

# Feature creada hace 5 días
# Nunca sincronizada con main
# → Conflictos masivos


Por qué: Mientras más tiempo pasa, peores los conflictos

NO eliminar branches antes de mergear a main

git branch -D feature/nombre  # ❌ antes de merge a main


Por qué: Pierdes el trabajo si los PRs no están mergeados

Troubleshooting

Problema: PRs no se crearon automáticamente

Síntomas:

Hice push de feature/* pero no veo los 3 PRs


Soluciones:

Verificar permisos:

Settings → Actions → General → Workflow permissions
☑ Allow GitHub Actions to create and approve pull requests


Ver logs:

Actions → Auto-crear PRs → Ver último run


Crear manualmente:

gh pr create --base dev --head feature/nombre --title "[DEV] nombre"
gh pr create --base stg --head feature/nombre --title "[STG] nombre" --draft
gh pr create --base main --head feature/nombre --title "[PROD] nombre" --draft


Problema: CI falla en "Generate Prisma Client"

Síntomas:

Error: Missing required environment variable: DATABASE_URL


Solución:

Verificar que el workflow tiene:

- name: Generate Prisma Client
  run: pnpm db:generate
  env:
    DATABASE_URL: "postgresql://fake:fake@localhost:5432/fake"


Problema: Branches divergieron

Síntomas:

main tiene: Feature A
stg tiene: Feature A + Feature B
dev tiene: Feature A + Feature B + Feature C


Solución:

Sincronización manual (semanal):

# main → stg
git checkout stg
git pull origin stg
git merge origin/main
git push origin stg

# main → dev
git checkout dev
git pull origin dev
git merge origin/main
git push origin dev


Problema: Feature se cancela

Síntomas:

Feature ya no se va a desarrollar
PRs quedan abiertos

Solución:

# 1. Cerrar los 3 PRs en GitHub (sin mergear)

# 2. Eliminar branch
git push origin --delete feature/nombre

# 3. Si ya hizo merge a dev:
# Crear PR para revertir
git checkout dev
git revert <commit-hash>
git push origin dev

FAQ

¿Por qué crear desde main y no desde dev?

Respuesta:

Porque cada feature debe ser independiente. Si creas desde dev:

Tu feature incluye código de otras features que pueden no llegar a main

Si esas features se cancelan, la tuya tiene código "basura"

Conflictos más complejos

Crear desde main garantiza que solo tienes código estable de producción.

¿Qué pasa si una feature nunca llega a main?

Respuesta:

Se queda en dev o stg indefinidamente. Opciones:

A) Dejarla ahí (si puede servir después) B) Revertirla (si bloquea algo) C) Archivar el branch (para referencia)

# Revertir en dev
git checkout dev
git revert <commit-hash>
git push origin dev


¿Cómo hago un hotfix urgente?

Respuesta:

Hotfix sigue el mismo flujo pero acelerado:

# 1. Crear desde main
git checkout main
git checkout -b hotfix/critical-bug-999

# 2. Fix
git commit -m "fix: critical production bug"
git push -u origin hotfix/critical-bug-999

# 3. PRs se crean automáticamente

# 4. Fast-track approvals
# - Mergear a dev inmediatamente
# - Mergear a stg con 1 approval rápida
# - Mergear a main con 2 approvals urgentes

# Total: ~1-2 horas en vez de días


¿Puedo tener múltiples features en progreso?

Respuesta:

Sí, sin problema. Cada feature es independiente:

git checkout main

# Feature 1
git checkout -b feature/login
# ... trabajo ...
git push -u origin feature/login

# Feature 2
git checkout main
git checkout -b feature/dashboard
# ... trabajo ...
git push -u origin feature/dashboard


Cada una tendrá sus propios 3 PRs.

¿Qué hago si main cambia mientras desarrollo?

Respuesta:

Sync con rebase (diariamente):

git fetch origin
git rebase origin/main
# Resolver conflictos si hay
git push --force-with-lease origin feature/nombre


Esto mantiene tu feature actualizada con los últimos cambios de producción.

¿Por qué MERGE y no SQUASH?

Respuesta:

MERGE:

Preserva historial completo

Git sabe que es el mismo código en dev/stg/main

Fácil sincronizar después

SQUASH:

Crea commits diferentes en cada branch

Git piensa que son cambios distintos

Rompe la sincronización

Ejemplo:

# Con MERGE
feature → dev (commits A, B, C)
feature → stg (commits A, B, C) ← mismo historial
feature → main (commits A, B, C) ← mismo historial

# Con SQUASH (MAL)
feature → dev (commit X = A+B+C combinados)
feature → stg (commit Y = A+B+C combinados)
feature → main (commit Z = A+B+C combinados)
# X, Y, Z son commits DIFERENTES
# Git no sabe que son lo mismo

Checklist para Nuevos Devs

Primera Vez

Verificar configuración:
☐ pnpm -v (verificar versión)
☐ node -v (verificar versión)
☐ pnpm install (instalar dependencies)
☐ pnpm run lint (verificar que funciona)
☐ pnpm run typecheck (verificar que funciona)
☐ pnpm run build (verificar que funciona)


Por Cada Feature

Inicio:
☐ git checkout main && git pull origin main
☐ git checkout -b feature/[equipo]-[nombre]-[TICKET]
☐ git push -u origin feature/[nombre]
☐ Verificar que se crearon 3 PRs en GitHub

Durante desarrollo:
☐ Commits frecuentes (feat/fix/docs/refactor)
☐ Push diario
☐ Sync con main cada mañana
☐ Verificar que CI pase

PR a dev:
☐ CI pasa (lint + typecheck + build)
☐ Tests OK
☐ Mergear sin esperar approval

PR a stg:
☐ Cambiar de draft a ready
☐ Solicitar QA testing
☐ Esperar 1 approval + QA sign-off
☐ Mergear

PR a main:
☐ Cambiar de draft a ready
☐ Solicitar 2+ approvals tech leads
☐ Todos los tests pasando
☐ Mergear
☐ Verificar deploy a producción

Cleanup:
☐ Verificar que branch fue eliminado
☐ git fetch --prune