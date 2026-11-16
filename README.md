# تيسير الأغا — متجر قطع غيار فولكسفاغن جولف

موقع ثنائي اللغة (العربية/English) مع كتالوج منتجات ولوحة إدارة مرتبطة بـ Supabase/PostgreSQL.

## ما الذي يلزم لتشغيل قاعدة البيانات؟

لم أستطع إنشاء قاعدة بيانات مستضافة من داخل مستودع GitHub وحده؛ يلزم أن تنشئ مشروع Supabase في حسابك. لا تضع مفاتيح سرية في ملفات المستودع.

1. أنشئ مشروعًا في [Supabase](https://supabase.com/).
2. افتح **SQL Editor** وشغّل `supabase/schema.sql`.
3. انسخ **Project URL** و **anon/public key** من إعدادات المشروع.
4. انسخهما إلى `js/supabase-config.js` (هذا المفتاح مخصص للواجهة الأمامية ويظل آمنًا فقط مع سياسات RLS المفعّلة).
5. أنشئ مستخدمًا من **Authentication → Users**، ثم اجعله مديرًا بتشغيل SQL التالي بعد استبدال البريد:

```sql
insert into public.profiles (id, role)
select id, 'admin' from auth.users where email = 'YOUR_ADMIN_EMAIL'
on conflict (id) do update set role = 'admin';
```

6. انشر المستودع عبر **Settings → Pages → Deploy from a branch → main / (root)**.

> لا تستخدم كلمة مرور ثابتة مثل `2008` للوحة المنشورة. لوحة الإدارة تستخدم Supabase Auth. لا تشارك `service_role` key أبدًا ولا تضعه في المتصفح.

## الملفات

- `index.html` — واجهة المتجر العربية والإنجليزية.
- `admin.html` — تسجيل دخول آمن عبر Supabase Auth وإدارة المنتجات.
- `js/supabase-config.js` — إعدادات اتصال الواجهة، أضف Project URL و anon key هنا.
- `supabase/schema.sql` — الجداول والفهارس وسياسات الوصول (RLS).

المنتجات تُقرأ من قاعدة البيانات، ولا تظهر إلا المنتجات النشطة. لا تتوفر معالجة دفع أو شحن آلي في هذا الإصدار؛ يمكن إضافة التكامل لاحقًا.
