import { z } from 'zod';

export const authCredentialsSchema = z.object({
  email: z.string().trim().email('Enter a valid email address.'),
  password: z.string().min(8, 'Use at least 8 characters.'),
});

export type AuthCredentials = z.infer<typeof authCredentialsSchema>;
