import type { AtlasRepositories } from '@/src/lib/database/repositories';

export async function seedAtlasDevData(repositories: AtlasRepositories): Promise<void> {
  const existingCompounds = await repositories.compounds.listAll();

  if (existingCompounds.length === 0) {
    await repositories.compounds.create({
      slug: 'wegovy',
      displayName: 'Wegovy',
      compoundType: 'glp',
      isUserDefined: false,
      notes: 'Default dev seed compound.',
    });
    await repositories.compounds.create({
      slug: 'bpc-157',
      displayName: 'BPC-157',
      compoundType: 'peptide',
      isUserDefined: false,
      notes: 'Default dev seed peptide.',
    });
  }

  const existingSites = await repositories.sites.listAll();

  if (existingSites.length === 0) {
    await repositories.sites.create({
      name: 'Abdomen',
      bodyArea: 'abdomen',
      notes: 'Example injection site for local development.',
    });
    await repositories.sites.create({
      name: 'Thigh',
      bodyArea: 'thigh',
      notes: 'Example rotation site for local development.',
    });
  }
}
