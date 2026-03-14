import type { AtlasRepositories } from '@/src/lib/database/repositories';
import type { ScheduledProtocolRevisionBundle } from '@/src/lib/schedule/protocol-revision-schedule';

type BundleDependencies = {
  includeLogs?: boolean;
  repositories?: AtlasRepositories;
};

export async function getProtocolRevisionBundleById(
  protocolId: string,
  dependencies: BundleDependencies = {}
): Promise<ScheduledProtocolRevisionBundle | null> {
  const bundles = await listProtocolRevisionBundles(dependencies);
  return bundles.find((bundle) => bundle.protocol.id === protocolId) ?? null;
}

export async function listProtocolRevisionBundles(
  dependencies: BundleDependencies = {}
): Promise<ScheduledProtocolRevisionBundle[]> {
  const repositories =
    dependencies.repositories ?? (await (await import('@/src/lib/database')).getAtlasRepositories());
  const [compounds, protocols, revisionRules, revisions, logEvents] = await Promise.all([
    repositories.compounds.listAll(),
    repositories.protocols.listAll(),
    repositories.protocolRevisionRules.listAll(),
    repositories.protocolRevisions.listAll(),
    dependencies.includeLogs ? repositories.logEvents.listAll() : Promise.resolve([]),
  ]);

  return protocols.map((protocol) => {
    const protocolRevisions = revisions
      .filter((revision) => revision.protocolId === protocol.id)
      .map((revision) => ({
        revision,
        rules: revisionRules.filter((rule) => rule.revisionId === revision.id),
      }));

    return {
      compound: compounds.find((compound) => compound.id === protocol.compoundId) ?? null,
      logEvents: dependencies.includeLogs
        ? logEvents.filter((event) => event.protocolId === protocol.id)
        : undefined,
      protocol,
      revisions: protocolRevisions,
    };
  });
}
