#ifndef CMULTITOUCHSHIM_H
#define CMULTITOUCHSHIM_H

#include <stdbool.h>

typedef struct {
    float x;
    float y;
} SwooshyMTPoint;

typedef struct {
    SwooshyMTPoint position;
    SwooshyMTPoint velocity;
} SwooshyMTVector;

typedef struct {
    int frame;
    double timestamp;
    int identifier;
    int state;
    int unknown1;
    int unknown2;
    SwooshyMTVector normalized;
    float size;
    int unknown3;
    float angle;
    float majorAxis;
    float minorAxis;
    SwooshyMTVector millimeters;
    int unknown5_1;
    int unknown5_2;
    float unknown6;
} SwooshyMTFinger;

typedef void (*SwooshyMTContactCallback)(
    int device,
    const SwooshyMTFinger *data,
    int fingerCount,
    double timestamp,
    int frame,
    void *context
);

bool SwooshyMTStartMonitoring(SwooshyMTContactCallback callback, void *context);
void SwooshyMTStopMonitoring(void);

#endif
