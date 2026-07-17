-- Allow users to delete their own notifications.

DROP POLICY IF EXISTS "Eigene Notifications löschen" ON public.notifications;
CREATE POLICY "Eigene Notifications löschen"
  ON public.notifications FOR DELETE TO authenticated
  USING (user_id = auth.uid());
