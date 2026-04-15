#ifndef STORAGE_INTERFACE_H
#define STORAGE_INTERFACE_H

#include <QtPlugin>          // for Q_DECLARE_INTERFACE
#include "interface.h"

class StorageInterface : public PluginInterface
{
public:
    virtual ~StorageInterface() = default;
};

#define StorageInterface_iid "org.logos.StorageInterface"
Q_DECLARE_INTERFACE(StorageInterface, StorageInterface_iid)

#endif
