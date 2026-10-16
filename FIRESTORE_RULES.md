# Reglas de Seguridad de Firestore

Para que el módulo de chat funcione correctamente, necesitas configurar las siguientes reglas de seguridad en Firebase Firestore.

## Configuración Actual Requerida

Ve a la **Consola de Firebase** → **Firestore Database** → **Rules** y reemplaza las reglas actuales con:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Colección de usuarios
    match /users/{userId} {
      // Cualquier usuario autenticado puede leer información de otros usuarios
      allow read: if request.auth != null;
      // Solo el propio usuario puede escribir su información
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Colección de conversaciones
    match /conversations/{conversationId} {
      // Permitir lectura si el usuario es participante de la conversación
      allow read: if request.auth != null && 
                    request.auth.uid in resource.data.participant_ids;
      
      // Permitir creación de conversación si el usuario es uno de los participantes
      allow create: if request.auth != null && 
                      request.auth.uid in request.resource.data.participant_ids;
      
      // Permitir actualización solo a participantes (para marcar como leído, etc.)
      allow update: if request.auth != null && 
                      request.auth.uid in resource.data.participant_ids;
      
      // Permitir eliminación solo a participantes
      allow delete: if request.auth != null && 
                      request.auth.uid in resource.data.participant_ids;
      
      // Subcolección de mensajes dentro de cada conversación
      match /messages/{messageId} {
        // Permitir lectura si el usuario es participante de la conversación padre
        allow read: if request.auth != null && 
                      request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationId)).data.participant_ids;
        
        // Permitir creación si el usuario es participante y es el remitente del mensaje
        allow create: if request.auth != null && 
                        request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationId)).data.participant_ids &&
                        request.auth.uid == request.resource.data.sender_id;
        
        // Permitir actualización (marcar como leído)
        allow update: if request.auth != null && 
                        request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationId)).data.participant_ids;
        
        // Permitir eliminación solo del remitente
        allow delete: if request.auth != null && 
                        request.auth.uid == resource.data.sender_id;
      }
    }
  }
}
```

## Explicación de las Reglas

### Colección `users/`
- **Lectura**: Cualquier usuario autenticado puede leer perfiles de otros usuarios (necesario para mostrar nombres y avatares en chats)
- **Escritura**: Solo el propio usuario puede modificar su perfil

### Colección `conversations/`
- **Lectura**: Solo los participantes pueden ver la conversación
- **Creación**: Solo si el usuario que crea es uno de los participantes
- **Actualización**: Solo participantes (para marcar mensajes como leídos, actualizar último mensaje)
- **Eliminación**: Solo participantes

### Subcolección `conversations/{id}/messages/`
- **Lectura**: Solo participantes de la conversación padre
- **Creación**: Solo participantes, y solo si el sender_id coincide con el usuario autenticado
- **Actualización**: Solo participantes (para marcar como leído)
- **Eliminación**: Solo el remitente del mensaje

## Verificación de Reglas

Después de aplicar las reglas, puedes probarlas desde la consola de Firebase:

1. Ve a **Firestore Database** → **Rules**
2. Haz clic en **Rules Playground**
3. Prueba operaciones como:
   - `get` en `/conversations/{someId}`
   - `create` en `/conversations/{someId}/messages/{someId}`

## Notas Importantes

⚠️ **Seguridad**: Estas reglas asumen que estás usando **Supabase Auth** como sistema de autenticación principal, pero que Firebase está configurado para aceptar tokens personalizados de Supabase.

⚠️ **Token Personalizado**: Si no has configurado tokens personalizados de Firebase con Supabase, necesitarás hacerlo para que `request.auth.uid` funcione correctamente.

### Alternativa: Reglas Permisivas (Solo para Desarrollo)

Si estás en fase de desarrollo y quieres probar rápidamente sin configurar la autenticación completa:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // ⚠️ SOLO PARA DESARROLLO - NO USAR EN PRODUCCIÓN
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

**⚠️ ADVERTENCIA**: Estas reglas permiten acceso total sin autenticación. Solo úsalas temporalmente para desarrollo y pruebas.

## Integración con Supabase Auth

Para que las reglas funcionen correctamente con Supabase Auth, necesitas generar tokens personalizados de Firebase. Aquí está el flujo:

1. Usuario se autentica en Supabase
2. Tu backend (Cloud Function de Firebase o Edge Function de Supabase) genera un token personalizado de Firebase usando el UID de Supabase
3. Tu app Flutter usa ese token para autenticarse en Firebase
4. Las reglas de Firestore ahora pueden validar `request.auth.uid`

### Ejemplo de Cloud Function para Generar Token:

```javascript
// functions/src/index.ts
import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

admin.initializeApp();

export const createFirebaseToken = functions.https.onCall(async (data, context) => {
  const { supabaseUserId } = data;
  
  if (!supabaseUserId) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing supabaseUserId');
  }
  
  // Crear token personalizado con el UID de Supabase
  const customToken = await admin.auth().createCustomToken(supabaseUserId);
  
  return { token: customToken };
});
```

## Aplicar las Reglas

1. Copia las reglas apropiadas
2. Ve a Firebase Console → Firestore Database → Rules
3. Pega las reglas
4. Haz clic en **Publish**
5. Espera unos segundos para que se propaguen

## Verificación

Después de aplicar las reglas, la búsqueda de jugadores debería funcionar correctamente. El error `permission-denied` desaparecerá.

---

**Estado Actual del Código**: El código ya está preparado para manejar errores de Firestore gracefully, mostrando los jugadores incluso si no se pueden cargar las conversaciones existentes.
