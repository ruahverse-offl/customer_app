import { Redirect } from 'expo-router';

import { useAuth } from '@/context/AuthContext';
import { HREF_HOME } from '@/lib/navigation';

/**
 * Cold start: redirect all users to the home screen (customer app only)
 */
export default function Index() {
  const { loading } = useAuth();

  if (loading) {
    return null;
  }

  return <Redirect href={HREF_HOME} />;
}
