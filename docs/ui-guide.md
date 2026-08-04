# UI Guide

This guide provides an overview of the Logos Storage UI and how to use it.

## Onboarding 

**Case 1.** The default settings suit you.

In this case, you should use the `Guided` setup option. The node runs on the default configuration: TCP `8500` for data transfer and UDP `9090`
for discovery. You will need to forward both ports in your router.

**Case 2.** You need to manually configure the network settings or would like to modify other node configuration options.

In this case, you should use the `Advanced` setup option. This will display a prepopulated configuration JSON which you can then manually edit to suit your needs. See the module's [API reference](https://logos-co.github.io/logos-storage-module/latest/api_reference.html) for a list of configuration options.

Both options then ask you where downloaded files should be saved. Clicking `Continue` opens the dashboard and starts the node. Once it is
running, a small dot next to the node status reports the AutoNAT verdict: grey and labelled `Unknown` while it has no answer yet, green and
`Reachable` if other peers can reach you, orange and `Not reachable` otherwise. If it turns orange, you will need to
[troubleshoot](#troubleshooting) your connection. You can still use the app, but you will only be able to _download_ files from other nodes.


## Sharing a File

To share a file, locate the upload panel and click on it. This will open a file selector. Select the file you would like to share and click
`Open`. This will upload the file into the node and begin sharing it with other nodes in the network. The Content Identifier (CID) for the
file -- a string like `zDvZRwzm49ZJLzxheYtydzx6AcNVSrf69LriUWjPr1SNLVnaXfj2` -- will be displayed in the upload panel. You can share this
string with other people to allow them to download the file.

## Downloading a File

To download a file, you must first paste the file's CID into the `Fetch manifest` panel and click `Fetch`. This will download the file's metadata from the network.
Once the metadata is downloaded, you will see an entry appearing in the `Manifests` list at the bottom of the UI. To download the file, click on the download icon
next to the entry and a file selector will open, allowing you to choose where to save the file. Once you select a location, the file will be downloaded.
The download progress widget will show progress in real-time.

## Deleting Files

To stop sharing a file, you can click on the trash bin icon close to the manifest entry corresponding to the file you want to stop sharing. This will delete
the file from the node and interrupt its sharing.

## Troubleshooting

Logos Storage requires your node to be reachable from the internet and, to that end, you must open two ports on your router:

1. **Discovery.** UDP, defaults to `9090`. Used for discovery and DHT operations.
2. **libp2p listen port.** TCP, defaults to `8500`. Used for data transfer and peer connections.

Problems in not being able to share files are commonly related to either one (or both) of those ports not being open or available.

### Node has no peers

**Symptom:**
The node starts successfully but never connects to any peer.

**Cause:**
This is typically due to the discovery being unavailable - for instance, if another process is already occupying its port.

**Fix:**
Ensure that no process is using port `9090`, or change the default port value in the advanced configuration.

### Node is unreachable

**Symptom:**
The node starts and connects to peers, but the status indicator turns orange.

**Cause:**
AutoNAT could not open a connection back to your node: the TCP listen port is not reachable from the internet, usually because it is not
forwarded on your router.

**Fix:**
Forward the TCP listen port (defaults to `8500`) to the machine running the node, or change it in the advanced configuration to a port you
can forward.

### Manual port forwarding

**Symptom:**
You configure the port forwarding with both UDP and TCP ports but the node remains unreachable.

**Cause:**
The ports are not open on your router.

**Fix:**
Make sure port forwarding is enabled for these ports on your router.
