# Toolchain Setup — Quartus pour Stratix V GS

## Version requise

**Quartus Prime Standard 21.1.1** — contenu dans `Quartus-21.1.1.850-linux-complete.tar`.

## Installation

```bash
# Extraire les deux composants nécessaires du tarball complet
tar -xf Quartus-21.1.1.850-linux-complete.tar -C /tmp/q21 \
  components/QuartusSetup-21.1.1.850-linux.run \
  components/stratixv-21.1.1.850.qdz

# 1. Installer Quartus base
chmod +x /tmp/q21/components/QuartusSetup-21.1.1.850-linux.run
/tmp/q21/components/QuartusSetup-21.1.1.850-linux.run \
  --mode unattended --accept_eula 1 --installdir ~/intelFPGA/21.1

# 2. Installer le device pack Stratix V
# ATTENTION: .qdz est un ZIP (pas un exécutable)
unzip -q /tmp/q21/components/stratixv-21.1.1.850.qdz -d ~/intelFPGA/21.1/

# Vérifier
ls ~/intelFPGA/21.1/quartus/common/devinfo/stratixv/ddb_stratixv_hdr.ddb
# → doit exister (sinon Quartus ne peut pas compiler pour Stratix V)
```

**Pourquoi le device pack doit être installé séparément :**
L'installeur Quartus de base ne peuple pas `devinfo/stratixv/`.
Sans ce dossier, Quartus produit : `BASIC_INFO's HDR file ... not installed`.
Le `.qdz` contient 3629 fichiers `.ddb` dans `quartus/common/devinfo/stratixv/`.

## Dépendances système (kernel 6.x)

```bash
# OpenSUSE Leap / Tumbleweed
sudo zypper install -y libnsl3

# Si libnsl.so.1 est introuvable (Quartus 18-21 en a besoin)
mkdir -p ~/lib64_shim
ln -sf /usr/lib64/libnsl.so.3 ~/lib64_shim/libnsl.so.1
# Ajouter à ~/.bashrc ou à chaque session:
export LD_LIBRARY_PATH=$HOME/lib64_shim:/usr/lib64:$LD_LIBRARY_PATH
```

## Licence

```bash
# 1. Générer une licence d'évaluation 90 jours
#    URL: https://licensing.intel.com
#    Produit: Quartus Prime Standard Edition
#    Fournir la MAC de la machine: ip link show | grep 'link/ether' | awk '{print $2}' | head -1

# 2. Télécharger license.dat et le placer :
mkdir -p ~/intelFPGA/18.1/licenses/
# copier license.dat ici

# 3. Exporter avant compilation
export LM_LICENSE_FILE=$HOME/intelFPGA/18.1/licenses/license.dat
```

## Compilation

```bash
cd StratixV/trivial/
export LD_LIBRARY_PATH=$HOME/lib64_shim:/usr/lib64
export LM_LICENSE_FILE=$HOME/intelFPGA/18.1/licenses/license.dat
~/intelFPGA/21.1/quartus/bin/quartus_sh --flow compile trivial
```

## Programmation (Quartus Pro 26.x ou Standard)

La programmation JTAG peut utiliser Quartus Pro (ne compile pas Stratix V mais programme tout SOF) :

```bash
~/altera_pro/26.1/quartus/bin/jtagd --foreground --debug --port 1309 &
sleep 2
~/altera_pro/26.1/quartus/bin/quartus_pgm -c 1 -m JTAG -o 'p;output_files/trivial.sof'
```

## Matrice de compatibilité complète

| Quartus version | Edition | Synthèse Stratix V | Programmation |
|----------------|---------|------------------|---------------|
| 17.0 – 21.1 | **Standard** | ✅ | ✅ |
| 17.0 – 21.1 | Lite | ❌ | ✅ |
| 22.x – 26.x | Pro | ❌ | ✅ |
